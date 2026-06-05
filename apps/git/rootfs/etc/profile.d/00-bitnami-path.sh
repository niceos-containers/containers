# Preserve Bitnami-compatible command lookup.
#
# NiceOS app containers keep Bitnami-style application paths first so that
# /opt/bitnami commands take priority over system commands.

niceos_bitnami_path_clean=""

old_ifs="${IFS}"
IFS=":"
for niceos_bitnami_path_entry in ${PATH:-}; do
    case "${niceos_bitnami_path_entry}" in
        ""|/opt/bitnami/git/bin|/opt/bitnami/common/bin)
            ;;
        *)
            if [ -z "${niceos_bitnami_path_clean}" ]; then
                niceos_bitnami_path_clean="${niceos_bitnami_path_entry}"
            else
                niceos_bitnami_path_clean="${niceos_bitnami_path_clean}:${niceos_bitnami_path_entry}"
            fi
            ;;
    esac
done
IFS="${old_ifs}"

if [ -n "${niceos_bitnami_path_clean}" ]; then
    PATH="/opt/bitnami/git/bin:/opt/bitnami/common/bin:${niceos_bitnami_path_clean}"
else
    PATH="/opt/bitnami/git/bin:/opt/bitnami/common/bin"
fi

export PATH

unset niceos_bitnami_path_clean
unset niceos_bitnami_path_entry
unset old_ifs
