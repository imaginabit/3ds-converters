#!/usr/bin/env bash
# Batch CIA 3DS Decryptor Redux — Linux shell counterpart of the Windows .bat.
# Uses native bin/ctrdecrypt, bin/ctrtool, bin/makerom (no wine).
set -euo pipefail
cd "$(dirname "$0")"

ScriptVersion="v1.0.6.2-sh"
BIN=bin
CTRTOOL="$BIN/ctrtool"
CTRDECRYPT="$BIN/ctrdecrypt"
MAKEROM="$BIN/makerom"
SEEDDB="$BIN/seeddb.bin"
LOGFILE="log/programlog.txt"

mkdir -p log

now() { date '+%Y-%m-%d %H:%M:%S'; }
log()  { echo "$(now) = $1" >>"$LOGFILE"; }

banner() {
    echo "  ############################################################"
    echo "  ###  Batch CIA 3DS Decryptor Redux $ScriptVersion"
    echo "  ############################################################"
}

for tool in "$CTRTOOL" "$CTRDECRYPT" "$MAKEROM"; do
    [[ -x "$tool" ]] || { echo "Error: missing or not executable: $tool" >&2; exit 1; }
done

log "Batch CIA 3DS Decryptor Redux $ScriptVersion"
log "[i] Script started"

shopt -s nullglob
files_3ds=(*.3ds)
files_cia=(*.cia)
# drop already-decrypted
_keep=()
for f in "${files_3ds[@]}"; do [[ "$f" == *-decrypted* ]] || _keep+=("$f"); done
files_3ds=("${_keep[@]+"${_keep[@]}"}")
_keep=()
for f in "${files_cia[@]}"; do [[ "$f" == *-decrypted* ]] || _keep+=("$f"); done
files_cia=("${_keep[@]+"${_keep[@]}"}")

count3DS=${#files_3ds[@]}
countCIA=${#files_cia[@]}
totalCount=$((count3DS + countCIA))

if (( totalCount == 0 )); then
    banner; echo; echo "  No CIA or 3DS files found!"
    log "[!] No CIA or 3DS were found"; log "[i] Script execution ended"
    exit 1
fi

convertToCCI=0
if (( countCIA >= 1 )); then
    banner; echo
    if (( countCIA == 1 )); then
        echo "  A CIA file was found. Do you want to convert it to CCI?"
    else
        echo "  $countCIA CIA files were found. Do you want to convert them to CCI?"
    fi
    echo "  DLC, demos, system/TWL titles and updates cannot be converted."
    echo "  Default is No. If unsure choose No."
    echo
    read -r -p "  [Y] Yes / [N] No — Enter: " question
    case "${question,,}" in y|1) convertToCCI=1 ;; esac
fi

banner; echo; echo "  Decrypting..."
log "[i] Found $count3DS 3DS file(s), $countCIA CIA file(s). Start decrypting..."

finalCount=0; CIAErrCount=0; CCIErrCount=0; DSErrCount=0

cci_part_index() {
    case "${1,,}" in
        main) echo 0 ;; manual) echo 1 ;; downloadplay) echo 2 ;;
        partition4) echo 3 ;; partition5) echo 4 ;; partition6) echo 5 ;;
        n3dsupdatedata) echo 6 ;; updatedata) echo 7 ;; *) echo "" ;;
    esac
}

cleanup_ncch() { rm -f ./*.ncch 2>/dev/null || true; }

# Titles that cannot become CCI (same set as the .bat / GUI)
NO_CCI="000400db 0004001b 0004009b 00040010 00040030 00040130 0004000e 0004008c 00048005 0004800f 00048004 00040002"

decrypt_3ds() {
    local src="$1" stem="${1%.*}" out
    out="${stem}-decrypted.cci"
    if [[ -f "$out" ]]; then
        log "[^^] 3DS file \"$src\" was already decrypted"
        finalCount=$((finalCount + 1)); return
    fi
    # ctrdecrypt panics on .cci; same bytes work as .3ds
    local run_name="$src" tmp_3ds=""
    if [[ "$src" == *.cci ]]; then
        tmp_3ds="${stem}.tmp.3ds"
        ln -f "$src" "$tmp_3ds" 2>/dev/null || cp "$src" "$tmp_3ds"
        run_name="$tmp_3ds"
    fi
    if ! "$CTRDECRYPT" "$run_name" >/dev/null 2>&1; then
        [[ -n "$tmp_3ds" ]] && rm -f "$tmp_3ds"
        log "[!] Decrypting failed for file \"$src\""
        DSErrCount=$((DSErrCount + 1)); cleanup_ncch; return
    fi
    [[ -n "$tmp_3ds" ]] && rm -f "$tmp_3ds"

    local args=(-f cci -ignoresign -target p -o "$out") found=0 ncch idx part base
    for ncch in "${stem}".*.ncch *.ncch; do
        [[ -f "$ncch" ]] || continue
        base="${ncch%.ncch}"
        if [[ "$base" == "$stem".* ]]; then part="${base#"$stem".}"; else part="$base"; fi
        idx="$(cci_part_index "$part")"
        [[ -z "$idx" && "$part" =~ ^[0-9]+$ ]] && idx="$part"
        [[ -z "$idx" ]] && continue
        args+=(-i "$ncch:$idx:$idx"); found=1
    done
    if (( found == 0 )); then
        log "[!] Decrypting failed for file \"$src\" (no NCCH partitions)"
        DSErrCount=$((DSErrCount + 1)); cleanup_ncch; return
    fi
    if "$MAKEROM" "${args[@]}" >/dev/null 2>&1 && [[ -f "$out" ]]; then
        log "[i] Decrypting succeeded for file \"$src\""
        finalCount=$((finalCount + 1))
    else
        log "[!] Decrypting failed for file \"$src\""
        DSErrCount=$((DSErrCount + 1))
    fi
    cleanup_ncch
}

decrypt_cia() {
    local src="$1" stem="${1%.*}"
    # already decrypted?
    local existing=""
    for f in "${stem}"*-decrypted.cia; do [[ -f "$f" ]] && existing="$f" && break; done
    if [[ -n "$existing" ]]; then
        if (( convertToCCI == 1 )); then convert_cia_to_cci "$existing"
        else log "[^^] CIA file \"$src\" was already decrypted"; finalCount=$((finalCount + 1)); fi
        return
    fi

    local info title_id title_id_l version
    if ! info="$("$CTRTOOL" "--seeddb=$SEEDDB" "$src" 2>/dev/null)"; then
        log "[!] CIA is invalid [$src]"; CIAErrCount=$((CIAErrCount + 1)); return
    fi
    title_id="$(grep -oE 'Title id:[[:space:]]+[0-9a-fA-F]+' <<<"$info" | awk '{print $3}' | head -1 || true)"
    [[ -z "$title_id" ]] && title_id="$(grep -oE 'TitleId:[[:space:]]+[0-9a-fA-F]+' <<<"$info" | awk '{print $2}' | head -1 || true)"
    title_id_l="${title_id,,}"
    version="$(grep -oE 'TitleVersion:.*\(([0-9]+)\)' <<<"$info" | grep -oE '\([0-9]+\)' | tr -d '()' | head -1 || true)"

    if grep -qiE 'Crypto Key.*None' <<<"$info"; then
        log "[^^] CIA file \"$src\" [$title_id v${version:-?}] is already decrypted"
        CIAErrCount=$((CIAErrCount + 1)); return
    fi

    if ! "$CTRDECRYPT" "$src" >/dev/null 2>&1; then
        log "[!] Decrypting failed for file \"$src\""
        CIAErrCount=$((CIAErrCount + 1)); cleanup_ncch; return
    fi

    local args=(-f cia -ignoresign -target p) label="Game" out
    case "$title_id_l" in
        0004008c*) label="DLC"; args+=(-dlc) ;;
        0004000e*) label="Patch" ;;
    esac
    if (( convertToCCI == 1 )); then
        out="${stem} ${label}-decfirst.cia"
    elif [[ "$label" == "Game" ]]; then
        out="${stem}-decrypted.cia"
    else
        out="${stem} ${label}-decrypted.cia"
    fi
    args+=(-o "$out")

    local ncch idx found=0
    for ncch in "${stem}".[0-9]*.ncch; do
        [[ -f "$ncch" ]] || continue
        idx="${ncch#"$stem".}"; idx="${idx%.ncch}"
        [[ "$idx" =~ ^[0-9]+$ ]] || continue
        args+=(-i "$ncch:$idx:$idx"); found=1
    done
    if (( found == 0 )); then
        log "[!] Decrypting failed for file \"$src\" (no NCCH partitions)"
        CIAErrCount=$((CIAErrCount + 1)); cleanup_ncch; return
    fi
    [[ -n "$version" ]] && args+=(-ver "$version")

    log "[i] Calling makerom for $label CIA [$title_id v${version:-?}]"
    if "$MAKEROM" "${args[@]}" >/dev/null 2>&1 && [[ -f "$out" ]]; then
        log "[i] Decrypting succeeded [$title_id v${version:-?}]"
        (( convertToCCI == 0 )) && finalCount=$((finalCount + 1))
    else
        log "[!] Decrypting failed [$title_id v${version:-?}]"
        CIAErrCount=$((CIAErrCount + 1)); cleanup_ncch; return
    fi
    cleanup_ncch
    (( convertToCCI == 1 )) && convert_cia_to_cci "$out"
}

convert_cia_to_cci() {
    local cia="$1" stem="${1%.cia}" base out
    base="$stem"
    base="${base% *-decfirst}"; base="${base%-decrypted}"; base="${base% *-decrypted}"
    out="${base}-decrypted.cci"

    local info tid
    info="$("$CTRTOOL" "--seeddb=$SEEDDB" "$cia" 2>/dev/null || true)"
    tid="$(grep -oE 'Title id:[[:space:]]+[0-9a-fA-F]+' <<<"$info" | awk '{print $3}' | head -1 || true)"
    tid="${tid,,}"
    for t in $NO_CCI; do
        if [[ "$tid" == "$t"* ]]; then
            rm -f "$cia"
            log "[^^] Converting to CCI not supported for this title [$tid]"
            CCIErrCount=$((CCIErrCount + 1)); return
        fi
    done

    if "$MAKEROM" -ciatocci "$cia" -o "$out" >/dev/null 2>&1 && [[ -f "$out" ]]; then
        rm -f "$cia"
        log "[i] Converting to CCI succeeded [$out]"
        finalCount=$((finalCount + 1))
    else
        log "[!] Converting to CCI failed [$cia]"
        rm -f "$cia"; CCIErrCount=$((CCIErrCount + 1))
    fi
}

for f in "${files_3ds[@]+"${files_3ds[@]}"}"; do decrypt_3ds "$f"; done
for f in "${files_cia[@]+"${files_cia[@]}"}"; do decrypt_cia "$f"; done
cleanup_ncch

banner; echo
if (( finalCount == 0 )); then
    echo "  No files were decrypted!"; log "[!] No files were decrypted"
elif (( CIAErrCount + CCIErrCount + DSErrCount > 0 )) || (( finalCount != totalCount )); then
    echo "  Some files were not decrypted!"
    echo "  Summary:"
    (( count3DS > 0 )) && echo "  - $count3DS 3DS file(s), $DSErrCount failed"
    (( countCIA > 0 )) && echo "  - $countCIA CIA file(s), $CIAErrCount failed, $CCIErrCount CCI convert failed"
    echo "  - decrypted/converted OK: $finalCount / $totalCount"
    log "[^^] Some files were not decrypted"
else
    echo "  Decrypting finished!"
    echo "  - $finalCount / $totalCount file(s) OK"
    log "[i] Decrypting process succeeded"
fi
echo
echo "  Please review \"$LOGFILE\" for more details."
log "[i] Script execution ended"
