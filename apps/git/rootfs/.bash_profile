# NiceOS Bitnami-compatible login shell finalization.
#
# /etc/profile may reorder PATH after sourcing /etc/profile.d. Since NiceOS
# Bitnami-compatible containers use HOME=/, this file is read by bash login
# shells after /etc/profile and restores the final command lookup contract.

if [ -r /etc/profile.d/00-bitnami-path.sh ]; then
    . /etc/profile.d/00-bitnami-path.sh
fi
