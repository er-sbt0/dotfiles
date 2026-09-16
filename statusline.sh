#!/bin/bash
# Claude Code statusline for Check Point enterprise seats (Linux / Coder workspaces).
# Adapted from https://github.com/daniel3303/ClaudeCodeStatusLine v1.4.4 (Linux-only rewrite).
# Theme-neutral: uses standard ANSI colors, follows your terminal theme.
#
# Install:
#   1. cp statusline-team.sh ~/.claude/statusline.sh && chmod +x ~/.claude/statusline.sh
#   2. Add to ~/.claude/settings.json:
#        "statusLine": {
#          "type": "command",
#          "command": "~/.claude/statusline.sh",
#          "padding": 0,
#          "refreshInterval": 60
#        }
#   3. Start a new Claude Code session.
#
# Layout: model  |  dir@branch (+a -d)  |  ctx used/total (pct)  |  effort  |  5h  |  7d all . <model>
#
# Rate limits come primarily from the OAuth usage API (works on the CP enterprise
# subscription; verified 2026-07-22). That endpoint also exposes the model-scoped
# weekly limit (.limits[] kind=weekly_scoped), which stdin rate_limits does not
# carry. stdin rate_limits (documented for Pro/Max only) is kept as a fallback.
# The token is read at runtime from your own Claude Code credential store
# (~/.claude/.credentials.json); nothing is embedded in this script.
# Both weekly limits reset together, so their reset time is shown once.
# The currently binding limit (is_active) gets a highlighted label.

set -f

input=$(cat)
[ -z "$input" ] && { printf 'Claude'; exit 0; }

# Standard ANSI colors (256-color orange), adapt to the terminal theme
purple=$'\033[35m'
cyan=$'\033[36m'
green=$'\033[32m'
orange=$'\033[38;5;208m'
yellow=$'\033[33m'
red=$'\033[31m'
pink=$'\033[95m'
fg=$'\033[39m'
dim=$'\033[2m'
reset=$'\033[0m'
sep="  ${dim}|${reset}  "

# Threshold color for a usage percentage: green <50, yellow >=50, orange >=70, red >=90
usage_color() {
    local pct=${1%%.*}
    if   [ "${pct:-0}" -ge 90 ] 2>/dev/null; then printf '%s' "$red"
    elif [ "${pct:-0}" -ge 70 ] 2>/dev/null; then printf '%s' "$orange"
    elif [ "${pct:-0}" -ge 50 ] 2>/dev/null; then printf '%s' "$yellow"
    else printf '%s' "$green"; fi
}

format_tokens() {
    local n=${1:-0}
    if   [ "$n" -ge 1000000 ]; then awk -v n="$n" 'BEGIN{v=n/1000000; printf (v==int(v)?"%dm":"%.1fm"), v}'
    elif [ "$n" -ge 1000 ];    then awk -v n="$n" 'BEGIN{printf "%.0fk", n/1000}'
    else printf '%d' "$n"; fi
}

# ===== Parse stdin in a single jq pass =====
eval "$(jq -r '@sh "
model=\(.model.display_name // "Claude")
cwd=\(.cwd // "")
effort=\(.effort.level // "")
ctx_size=\(.context_window.context_window_size // 200000)
ctx_pct=\(.context_window.used_percentage // "")
in_tok=\(.context_window.current_usage.input_tokens // 0)
cc_tok=\(.context_window.current_usage.cache_creation_input_tokens // 0)
cr_tok=\(.context_window.current_usage.cache_read_input_tokens // 0)
rl_5h_pct=\(.rate_limits.five_hour.used_percentage // "")
rl_5h_reset=\(.rate_limits.five_hour.resets_at // "")
rl_7d_pct=\(.rate_limits.seven_day.used_percentage // "")
rl_7d_reset=\(.rate_limits.seven_day.resets_at // "")
"' <<<"$input" 2>/dev/null)"

# "Opus 4.8 (1M context)" -> "Opus 4.8 1M"
case "$model" in *" context)"*) model=$(sed 's/ *(\([0-9.]*[kKmM]*\) context)/ \1/' <<<"$model");; esac

[ "$ctx_size" -gt 0 ] 2>/dev/null || ctx_size=200000
ctx_used=$(( in_tok + cc_tok + cr_tok ))
[ -z "$ctx_pct" ] && ctx_pct=$(( ctx_used * 100 / ctx_size ))
ctx_pct=${ctx_pct%%.*}

out="${purple}${model}${reset}"

# ===== Directory + git =====
if [ -n "$cwd" ]; then
    out+="${sep}${cyan}${cwd##*/}${reset}"
    branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        # Ellipsize long branch names, keep both ends
        [ ${#branch} -gt 24 ] && branch="${branch:0:11}…${branch: -11}"
        out+="${dim}@${reset}${green}${branch}${reset}"
        stat=$(git -C "$cwd" diff --numstat 2>/dev/null | awk '{a+=$1; d+=$2} END {if (a+d>0) printf "+%d\t-%d", a, d}')
        [ -n "$stat" ] && out+=" ${dim}(${reset}${green}${stat%%$'\t'*}${reset} ${red}${stat##*$'\t'}${reset}${dim})${reset}"
    fi
fi

# ===== Context =====
out+="${sep}${orange}$(format_tokens "$ctx_used")/$(format_tokens "$ctx_size")${reset}"
out+=" ${dim}(${reset}$(usage_color "$ctx_pct")${ctx_pct}%${reset}${dim})${reset}"

# ===== Effort (bare colored value, no label) =====
config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
[ -z "$effort" ] && effort=$(jq -r '.effortLevel // "medium"' "$config_dir/settings.json" 2>/dev/null)
out+="$sep"
case "$effort" in
    low)    out+="${dim}low${reset}" ;;
    medium) out+="${orange}med${reset}" ;;
    high)   out+="${green}high${reset}" ;;
    xhigh)  out+="${purple}xhigh${reset}" ;;
    max)    out+="${red}max${reset}" ;;
    *)      out+="${fg}${effort:-?}${reset}" ;;
esac

# ===== Rate limits: OAuth usage API, cached 60s, shared across sessions =====
cache_dir="/tmp/claude-statusline-${USER:-coder}"
cache_file="$cache_dir/usage.json"
mkdir -p "$cache_dir" 2>/dev/null

needs_refresh=true
if [ -s "$cache_file" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
    [ "$age" -lt 60 ] && needs_refresh=false
fi

if $needs_refresh; then
    touch "$cache_file" 2>/dev/null   # stampede guard for parallel sessions
    token="${CLAUDE_CODE_OAUTH_TOKEN:-$(jq -r '.claudeAiOauth.accessToken // empty' "$config_dir/.credentials.json" 2>/dev/null)}"
    if [ -n "$token" ]; then
        resp=$(curl -s --max-time 4 \
            -H "Authorization: Bearer $token" \
            -H "anthropic-beta: oauth-2025-04-20" \
            -H "Accept: application/json" \
            "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
        if jq -e '.limits' <<<"$resp" >/dev/null 2>&1; then
            printf '%s' "$resp" >"$cache_file"
        fi
    fi
    # Drop an empty stampede sentinel so the next run retries instead of waiting 60s
    [ -s "$cache_file" ] || rm -f "$cache_file" 2>/dev/null
fi

limits_out=""
if [ -s "$cache_file" ]; then
    sess_pct="" sess_rst="" sess_act=""
    wa_pct=""   wa_rst=""   wa_act=""
    ws_pct=""   ws_rst=""   ws_act="" ws_name=""
    while IFS=$'\t' read -r kind pct rst active mname; do
        case "$kind" in
            session)       sess_pct=$pct; sess_rst=$rst; sess_act=$active ;;
            weekly_all)    wa_pct=$pct;   wa_rst=$rst;   wa_act=$active ;;
            weekly_scoped) ws_pct=$pct;   ws_rst=$rst;   ws_act=$active; ws_name=$mname ;;
        esac
    done < <(jq -r '.limits[]? | [.kind, (.percent // 0 | round), (.resets_at // ""), (.is_active // false), (.scope.model.display_name // "")] | @tsv' "$cache_file" 2>/dev/null)

    if [ -n "$sess_pct" ]; then
        if [ "$sess_act" = "true" ]; then lbl="${pink}5h${reset}"; else lbl="${fg}5h${reset}"; fi
        seg="${lbl} $(usage_color "$sess_pct")${sess_pct}%${reset}"
        if [ -n "$sess_rst" ]; then
            t=$(date -d "$sess_rst" +%H:%M 2>/dev/null)
            [ -n "$t" ] && seg+=" ${dim}@${t}${reset}"
        fi
        limits_out+="${sep}${seg}"
    fi

    # Weekly segment: overall and model-scoped share one reset time, shown once
    if [ -n "$wa_pct" ] || [ -n "$ws_pct" ]; then
        seg=""
        if [ -n "$wa_pct" ]; then
            if [ "$wa_act" = "true" ]; then lbl="${pink}7d all${reset}"; else lbl="${fg}7d${reset} ${dim}all${reset}"; fi
            seg+="${lbl} $(usage_color "$wa_pct")${wa_pct}%${reset}"
        fi
        if [ -n "$ws_pct" ]; then
            [ -n "$seg" ] && seg+=" ${dim}·${reset} "
            if [ "$ws_act" = "true" ]; then lbl="${pink}${ws_name:-model}${reset}"; else lbl="${dim}${ws_name:-model}${reset}"; fi
            seg+="${lbl} $(usage_color "$ws_pct")${ws_pct}%${reset}"
        fi
        rst="${ws_rst:-$wa_rst}"
        if [ -n "$rst" ]; then
            t=$(date -d "$rst" +'%a %H:%M' 2>/dev/null)
            [ -n "$t" ] && seg+=" ${dim}@${t}${reset}"
        fi
        limits_out+="${sep}${seg}"
    fi
fi

# Fallback: stdin rate_limits (resets_at is epoch seconds here)
if [ -z "$limits_out" ] && { [ -n "$rl_5h_pct" ] || [ -n "$rl_7d_pct" ]; }; then
    if [ -n "$rl_5h_pct" ]; then
        p=${rl_5h_pct%%.*}
        seg="${fg}5h${reset} $(usage_color "$p")${p}%${reset}"
        [ -n "$rl_5h_reset" ] && seg+=" ${dim}@$(date -d "@$rl_5h_reset" +%H:%M 2>/dev/null)${reset}"
        limits_out+="${sep}${seg}"
    fi
    if [ -n "$rl_7d_pct" ]; then
        p=${rl_7d_pct%%.*}
        seg="${fg}7d${reset} $(usage_color "$p")${p}%${reset}"
        [ -n "$rl_7d_reset" ] && seg+=" ${dim}@$(date -d "@$rl_7d_reset" +'%a %H:%M' 2>/dev/null)${reset}"
        limits_out+="${sep}${seg}"
    fi
fi

[ -z "$limits_out" ] && limits_out="${sep}${fg}limits${reset} ${dim}-${reset}"
out+="$limits_out"

printf '%s' "$out"
exit 0
