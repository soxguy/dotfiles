# ~/.config/zsh/second_brain.zsh
#
# Second-brain knowledge base shell integration
# Managed by chezmoi — do not edit directly
#
# SECOND_BRAIN_SUBDIR and SECOND_BRAIN_KNOWLEDGE_SUBDIR are set by exports.zsh (from Bitwarden).
# Full paths are constructed here so no absolute paths are stored anywhere.

export SECOND_BRAIN_DIR="${HOME}/${SECOND_BRAIN_SUBDIR}"
export SECOND_BRAIN_KNOWLEDGE_DIR="${HOME}/${SECOND_BRAIN_KNOWLEDGE_SUBDIR}"

second-brain() {
  local cmd="${1:-help}"; shift 2>/dev/null
  case "$cmd" in
    health)
      if [[ -n "$1" ]]; then
        python3 "${SECOND_BRAIN_DIR}/tools/health.py" "${SECOND_BRAIN_DIR}/domains/${1}/wiki"
      else
        bash "${SECOND_BRAIN_DIR}/tools/for_each_domain.sh" \
          "python3 ${SECOND_BRAIN_DIR}/tools/health.py {wiki}"
      fi
      ;;
    ingest) python3 "${SECOND_BRAIN_DIR}/tools/ingest.py" "$@" ;;
    query)  python3 "${SECOND_BRAIN_DIR}/tools/query.py"  "$@" ;;
    cd)     cd "${SECOND_BRAIN_DIR}" ;;
    *)
      echo "Usage: second-brain <health|ingest|query|cd> [args]"
      echo "       sb <health|ingest|query|cd> [args]"
      ;;
  esac
}

alias sb=second-brain
