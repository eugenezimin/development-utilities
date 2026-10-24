# Terminal greeting: one table, each fact once. Rows that are normally fine
# (security, updates, sessions, kube/aws) only appear when they need attention.
#
# Shown once per terminal on the first prompt; run `motd` to print it again.
# `touch ~/.hushlogin` keeps the built-in "Last login" line quiet (the installer does this).

[[ $OSTYPE == darwin* ]] || return 0

zmodload -F zsh/stat b:zstat 2>/dev/null
zmodload zsh/datetime 2>/dev/null

# ── Settings (set these in .zsh_secrets or earlier conf.d files to override) ──
: ${MOTD_IP_TTL:=600}            # seconds to cache the public-IP lookup
: ${MOTD_SEC_TTL:=3600}          # seconds to cache security status and macOS updates
: ${MOTD_BREW_TTL:=86400}        # seconds between background `brew outdated` runs
: ${MOTD_CACHE:=${XDG_CACHE_HOME:-$HOME/.cache}/motd}

# ── Helpers ───────────────────────────────────────────────────────────────────
# _motd_c TEXT VALUE WARN CRIT [low]
# Colours TEXT green/yellow/red by VALUE. Higher is worse unless "low" is given.
_motd_c() {
  local -i v=${2%%.*} w=$3 c=$4 col=32
  [[ $5 == low ]] && (( v = -v, w = -w, c = -c ))
  (( v >= w )) && col=33
  (( v >= c )) && col=31
  print -rn -- $'\e['${col}m"$1"$'\e[0m'
}

# _motd_fresh FILE TTL — succeeds if FILE exists and is younger than TTL seconds
_motd_fresh() {
  local -a st
  zstat -A st +mtime -- "$1" 2>/dev/null || return 1
  (( EPOCHSECONDS - st[1] < $2 ))
}

# _motd_cache FILE TTL CMD... — keep FILE filled with CMD's output.
# A missing FILE is filled right away; a stale one is refreshed in the background
# so a new tab never waits on it. Failures are cached too (as an empty file).
_motd_cache() {
  local f=$1 ttl=$2; shift 2
  _motd_fresh $f $ttl && return 0
  if [[ -e $f ]]; then
    touch $f    # claim the refresh so parallel tabs don't all start one
    ( "$@" > $f.$$ 2>/dev/null; mv -f $f.$$ $f ) &>/dev/null &!
  else
    "$@" > $f 2>/dev/null
  fi
}

_motd_model() { ioreg -rd1 -k product-name | awk -F'<"|">' '/"product-name"/ {print $2; exit}' | tr -d '\0'; }

_motd_port() {
  networksetup -listallhardwareports |
    awk -F': ' -v d="$1" '/^Hardware Port/ {p=$2} $0 == "Device: " d {print p; exit}'
}

# Line 1: protections that are off; line 2: pending macOS updates
_motd_security() {
  local -a off
  [[ $(fdesetup isactive) == true ]] || off+=FileVault
  [[ $(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate) == *enabled* ]] || off+=Firewall
  [[ $(csrutil status) == *enabled* ]] || off+=SIP
  [[ $(spctl --status) == *enabled* ]] || off+=Gatekeeper
  print -r -- "${(j: :)off}"
  defaults read /Library/Preferences/com.apple.SoftwareUpdate LastRecommendedUpdatesAvailable || print 0
}

_motd_brew() { brew outdated --quiet | wc -l | tr -d ' '; }

# _motd_table TITLE RIGHT ROW... — ROW is "label<TAB>value", "-" is a divider.
# Widths ignore colour codes; values too wide for the terminal are cut with "…".
_motd_table() {
  local title=$1 right=$2; shift 2
  local B=$'\e[2m' L=$'\e[36m' R=$'\e[0m' sp= row k v
  local -i lw=0 vw=0 kw tw rw=${(m)#right} n cols=${COLUMNS:-0}
  (( cols > 0 )) || cols=80

  local -a rows
  for row in "$@"; do    # drop leading, trailing and repeated dividers
    [[ $row == - && ( $#rows == 0 || $rows[-1] == - ) ]] || rows+=("$row")
  done
  [[ $rows[-1] == - ]] && rows[-1]=()

  for row in $rows; do
    [[ $row == - ]] && continue
    k=${row%%$'\t'*} v=${row#*$'\t'}
    v=${v//$'\e'\[[0-9;]#m/}
    (( ${(m)#k} > lw )) && lw=${(m)#k}
    (( ${(m)#v} > vw )) && vw=${(m)#v}
  done
  v=${title//$'\e'\[[0-9;]#m/}; tw=${(m)#v}
  (( lw + vw + 7 < tw + rw + 9 )) && vw=$(( tw + rw + 9 - lw - 7 ))
  (( lw + vw + 7 > cols )) && vw=$(( cols - lw - 7 ))
  (( vw < 5 )) && vw=5
  local -i w=lw+vw+7

  # ╭─ title ─────── right ─╮   (right is dropped if it doesn't fit)
  n=$(( w - tw - rw - 8 ))
  if (( n < 1 )); then right=; n=$(( w - tw - 6 )); (( n < 1 )) && n=1; fi
  print -rn -- "${B}╭─${R} $title ${B}${(l:n::─:)sp}${R}"
  [[ -n $right ]] && print -rn -- " ${B}${right}${R} "
  print -r -- "${B}─╮${R}"

  for row in $rows; do
    if [[ $row == - ]]; then
      print -r -- "${B}├${(l:lw+2::─:)sp}┼${(l:vw+2::─:)sp}┤${R}"
      continue
    fi
    k=${row%%$'\t'*} v=${row#*$'\t'}
    kw=${(m)#k}
    local plain=${v//$'\e'\[[0-9;]#m/}
    if (( ${(m)#plain} > vw )); then
      v="${plain[1,vw-1]}…"; plain=$v
    fi
    n=$(( vw - ${(m)#plain} ))
    print -r -- "${B}│${R} ${L}${k}${R}${(l:lw-kw:)sp} ${B}│${R} ${v}${R}${(l:n:)sp} ${B}│${R}"
  done
  print -r -- "${B}╰${(l:lw+2::─:)sp}┴${(l:vw+2::─:)sp}╯${R}"
}

motd() {
  emulate -L zsh
  setopt extendedglob
  [[ -d $MOTD_CACHE ]] || mkdir -p -- "$MOTD_CACHE"
  local R=$'\e[0m' DIM=$'\e[2m' RED=$'\e[1;31m' T=$'\t'
  local line
  local -a rows

  # ── Hardware & kernel counters (one sysctl call, parsed by key) ─────────────
  local -A sc
  for line in ${(f)"$(sysctl hw.model machdep.cpu.brand_string hw.ncpu hw.memsize \
                      hw.perflevel0.physicalcpu hw.perflevel0.name \
                      hw.perflevel1.physicalcpu hw.perflevel1.name \
                      kern.boottime vm.loadavg kern.memorystatus_level vm.swapusage 2>/dev/null)"}; do
    sc[${line%%: *}]=${line#*: }
  done
  local -i cores=${sc[hw.ncpu]:-1}
  local -i memgb=$(( ${sc[hw.memsize]:-0} / 1024**3 ))
  local -i memfree=${sc[kern.memorystatus_level]:-0}
  local -a load=( ${=${sc[vm.loadavg]//[{}]/}} )
  local -i loadpct=$(( ${load[1]:-0} * 100 / cores ))
  local swap=${${=sc[vm.swapusage]}[6]}

  # ── Machine ─────────────────────────────────────────────────────────────────
  _motd_cache $MOTD_CACHE/model 315360000 _motd_model
  local model=$(<$MOTD_CACHE/model) chip=${sc[machdep.cpu.brand_string]#Apple }
  local mac=${model:-$sc[hw.model]}
  [[ -n $chip && $mac != *"$chip"* ]] && mac+=" · $chip"
  mac+=" · $cores cores"
  [[ -n $sc[hw.perflevel1.physicalcpu] ]] &&
    mac+=" (${sc[hw.perflevel0.physicalcpu]}${sc[hw.perflevel0.name][1]} + ${sc[hw.perflevel1.physicalcpu]}${sc[hw.perflevel1.name][1]})"
  [[ -n $model ]] && mac+=" ${DIM}${sc[hw.model]}${R}"

  local -A sw
  for line in ${(f)"$(sw_vers 2>/dev/null)"}; do
    sw[${line%%:*}]=${line##*[[:space:]]}
  done
  local os="${sw[ProductVersion]} (${sw[BuildVersion]})"

  local -i boot=${${sc[kern.boottime]#*sec = }%%,*} up=0
  (( boot )) && up=$(( EPOCHSECONDS - boot ))
  local uptime
  if   (( up >= 86400 )); then uptime="$(( up / 86400 ))d $(( up % 86400 / 3600 ))h"
  elif (( up >= 3600 ));  then uptime="$(( up / 3600 ))h $(( up % 3600 / 60 ))m"
  else                         uptime="$(( up / 60 ))m"
  fi
  (( up )) && os+=" · up $uptime"

  # ── Time: UTC · local · zone ────────────────────────────────────────────────
  local utc loc zone today
  TZ=UTC strftime -s utc '%H:%M UTC' $EPOCHSECONDS
  strftime -s loc '%H:%M %Z' $EPOCHSECONDS
  strftime -s today '%a %d %b %Y · week %V' $EPOCHSECONDS
  zone=${TZ:-$(zstat +link /etc/localtime 2>/dev/null)}
  zone=${zone#*zoneinfo/}
  local time=$utc
  [[ $loc != $utc ]] && time+=" · $loc"
  [[ -n $zone && $zone != UTC ]] && time+=" · $zone"

  # ── Disk (the Data volume is where your files actually live) ───────────────
  local -a df=( $(df -h /System/Volumes/Data 2>/dev/null | awk 'NR==2 {print $2, $3, $4, $5}') )
  (( $#df )) || df=( $(df -h / | awk 'NR==2 {print $2, $3, $4, $5}') )

  # ── Battery (skipped on desktops) ───────────────────────────────────────────
  local batt bl=$(pmset -g batt 2>/dev/null | awk 'NR==2')
  if [[ $bl == *InternalBattery* ]]; then
    local -a bp=( "${(@s:; :)bl}" )
    local -i pct=${${bl%%\%*}##*[^0-9]}
    local state=$bp[2] eta=${bp[3]%% present*}
    [[ $eta == *remaining && $eta != 0:00* ]] && eta=${eta% remaining}" left" || eta=
    local -a io=( $(ioreg -rn AppleSmartBattery | awk '
        /"CycleCount" = /          {c=$3}
        /"DesignCapacity" = /      {d=$3}
        /"AppleRawMaxCapacity" = / {r=$3}
        /"MaxCapacity" = /         {m=$3}
        END {print c+0, d+0, (r ? r : m)+0}') )
    batt="$(_motd_c "${pct}%" $pct 30 15 low) · ${state}${eta:+, $eta}"
    (( io[1] )) && batt+=" · ${io[1]} cycles"
    if (( io[2] && io[3] > 100 )); then
      local -i health=$(( io[3] * 100 / io[2] ))
      batt+=" · $(_motd_c "${health}% health" $health 85 80 low)"
    fi
  fi

  # ── Heaviest processes ──────────────────────────────────────────────────────
  local topcpu=$(ps -Arc -o pcpu= -o comm= | awk '{p=$1; $1=""; sub(/^ +/,"")} $0 != "ps" {printf "%s %s%%", $0, p; exit}')
  local topmem=$(ps -Amc -o rss= -o comm= | awk 'NR==1 {r=$1/1024; u="MB"; if (r >= 1024) {r/=1024; u="GB"}
                                                         $1=""; sub(/^ +/,""); printf "%s %.1f %s", $0, r, u}')

  # ── Network ─────────────────────────────────────────────────────────────────
  local route=$(route -n get default 2>/dev/null)
  local iface=$(awk '/interface:/ {print $2}' <<< $route)
  local gw=$(awk '/gateway:/ {print $2}' <<< $route)
  local net port lan wan where org dns
  if [[ -n $iface ]]; then
    lan=$(ipconfig getifaddr "$iface" 2>/dev/null)
    if [[ $iface == (utun|ppp|ipsec)* ]]; then
      port=VPN
    else
      _motd_cache $MOTD_CACHE/port-$iface 315360000 _motd_port $iface
      port=$(<$MOTD_CACHE/port-$iface)
    fi
    net="${port:-$iface}${port:+ ($iface)}${lan:+ · $lan}${gw:+ → $gw}"

    # Public IP + location, cached per network so switching Wi-Fi/VPN refreshes it
    local ipf=$MOTD_CACHE/ip-$iface-${gw//[^[:alnum:]]/_}
    _motd_cache $ipf $MOTD_IP_TTL curl -fsS --max-time 1 https://ipinfo.io/json
    local -a geo
    [[ -s $ipf ]] && geo=( "${(@f)$(awk '{gsub(/", *"/, "\"\n\"")} 1' $ipf |
        awk -F'"' '$2=="ip"{i=$4} $2=="city"{c=$4} $2=="country"{k=$4} $2=="org"{o=$4}
                   END {print i; print c; print k; print o}')}" )
    wan=$geo[1] org=${geo[4]#AS<-> }
    where=${(j:, :)${(@)geo[2,3]:#}}

    # Resolvers, only when they aren't simply the router
    local -a ns=( $(scutil --dns 2>/dev/null | awk '/^resolver #2/ {exit} /nameserver\[/ {print $3}') )
    if (( $#ns )) && [[ $ns[1] != $gw ]]; then
      dns=${(j: :)ns[1,3]}
      [[ $ns[1] == 100.100.100.100 ]] && dns+=" ${DIM}(Tailscale)${R}"
    fi
  else
    net=$(_motd_c offline 1 1 1)
  fi

  # ── Attention: only rows with something to act on ───────────────────────────
  _motd_cache $MOTD_CACHE/security $MOTD_SEC_TTL _motd_security
  local -a sec=( "${(@f)$(<$MOTD_CACHE/security)}" )
  local secoff
  [[ -n $sec[1] ]] && secoff=$'\e[31m'"${(j:  :)${(@)${=sec[1]}/%/ ✗}}"$R

  local -i osupd=${sec[2]:-0} brewout=0
  if (( $+commands[brew] )); then
    local bf=$MOTD_CACHE/brew-outdated
    [[ -e $bf ]] || touch -t 200001010000 $bf    # stale on purpose: first run goes to background
    _motd_cache $bf $MOTD_BREW_TTL _motd_brew
    brewout=$(<$bf)
  fi
  local updates
  (( osupd )) && updates="$(_motd_c "macOS: $osupd pending" 1 1 1)"
  (( brewout )) && updates+="${updates:+ · }$(_motd_c "Homebrew: $brewout outdated" $brewout 10 50)"

  local session prev logins
  if [[ -n $SSH_CLIENT ]]; then
    session="${TTY:+${TTY#/dev/} }from "$'\e[33m'"${SSH_CLIENT%% *}"$R
    prev=$(last -2 "$USER" 2>/dev/null | awk 'NR==2 && NF && $1 != "wtmp" {$1=""; sub(/^ +/,""); print}')
  fi
  local whoout=$(who)
  local -a others=( ${(u)${(f)"$(awk -v me="$USER" '$1 != me {print $1}' <<< $whoout)"}} )
  local -i remote=$(awk -v t="${TTY#/dev/}" '$2 != t && /\(.*\)/' <<< $whoout | wc -l)
  (( $#others )) && logins=${(j:, :)others}
  (( remote )) && logins+="${logins:+ · }$remote remote"

  local tunnel
  pgrep -qf sshuttle && tunnel="sshuttle running"

  local kube kc=${${KUBECONFIG:-$HOME/.kube/config}%%:*}
  [[ -r $kc ]] && kube=$(awk '/^current-context:/ {gsub(/"/,""); print $2}' $kc)
  [[ $kube == *prod* ]] && kube=$RED$kube$R
  local aws=$AWS_PROFILE
  [[ $aws == *prod* ]] && aws=$RED$aws$R

  # ── Output ──────────────────────────────────────────────────────────────────
  local host=$(scutil --get ComputerName 2>/dev/null)
  local -a pub=( $wan $where $org )
  local -a add=(
    "Mac$T$mac"  "macOS$T$os"  "Time$T$time"
    -
    "Load$T$(_motd_c "${(j: :)load}" $loadpct 70 100) ${DIM}(${loadpct}%)${R}"
    "Memory$T$(_motd_c "${memfree}% free" $memfree 30 15 low) of ${memgb} GB${${swap:#0.00M}:+ · swap $swap}"
    "Disk$T$(_motd_c "${df[4]} used" ${df[4]%\%} 80 90) · ${df[3]%i} free of ${df[1]%i}"
    "Battery$T$batt"
    "Top$T${topcpu:+CPU $topcpu}${topcpu:+${topmem:+ · }}${topmem:+RAM $topmem}"
    -
    "Network$T$net"
    "Public$T${(j: · :)pub}"
    "DNS$T$dns"  "Tunnel$T$tunnel"
    -
    "Security$T$secoff"  "Updates$T$updates"
    "Session$T$session"  "Previous$T$prev"  "Logins$T$logins"
    "Kube$T$kube"  "AWS$T$aws"
  )
  for line in $add; do
    [[ $line == - || -n ${line#*$T} ]] && rows+=("$line")    # skip empty rows
  done
  _motd_table $'\e[1m'"$USER@${host:-$HOST}"$R "$today" $rows
}

# Show once per terminal, not again in nested shells. Printed from the first prompt
# (scheduled after p10k's instant-prompt cleanup) rather than during startup.
if [[ -o interactive && -z $MOTD_SHOWN ]]; then
  export MOTD_SHOWN=1
  autoload -Uz add-zsh-hook
  zmodload zsh/sched
  _motd_once() {
    add-zsh-hook -d precmd _motd_once
    unfunction _motd_once
    sched +0 motd
  }
  add-zsh-hook precmd _motd_once
fi
