#
# deta
#
# Copyright (c) 2011 David Persson
#
# Distributed under the terms of the MIT License.
# Redistributions of files must retain the above copyright notice.
#
# @COPYRIGHT 2011 David Persson <nperson@gmx.de>
# @LICENSE   http://www.opensource.org/licenses/mit-license.php The MIT License
# @LINK      http://github.com/davidpersson/deta
#

msgok "Module %s loaded." "transfer"

# @FUNCTION: sync
# @USAGE: [source] [target] [ignore]
# @DESCRIPTION:
# Will rsync all directories and files from [source] to [target]. Thus files
# which have been removed in [source] will also be removed from [target].
# Specify a whitespace separated list of patterns to ignore. Files matching the
# patterns won't be transferred from [source] to [target].  This function has
# DRYRUN support. Symlinks are copied as symlinks.
sync() {
	if [[ $DRYRUN != "n" ]]; then
		msgdry "Pretending syncing from %s to target %s." $1 $2
	else
		msg "Syncing from %s to target %s." $1 $2
	fi
	rsync --stats -h -z -p -r --delete \
			$(_rsync_ignore "$3") \
			--links \
			--times \
			--verbose \
			$(_rsync_dryrun) \
			$1 $2
}

# @FUNCTION: sync_sanity
# @USAGE: [source] [target] [ignore]
# @DESCRIPTION:
# Performs sanity checks on a sync from [source] to [target]. Will ask for
# confirmation if and return 1 thus aborting the script when the errexit option
# is set. Best used right before the actual sync call. See the sync function
# for more information on behavior and arguments.
sync_sanity() {
	local backup=$DRYRUN
	DRYRUN="y"

	msgdry "Running sync sanity check."
	local out=$(sync $1 $2 "$3" 2>&1)

	DRYRUN=$backup

	set +o errexit # grep may not match nything at all.
	echo "$out" | grep deleting
	set -o errexit
	read -p "Looks good? (y/n) " continue

	if [[ $continue != "y" ]]; then
		return 1
	fi
}

# @FUNCTION: _rsync_ignore
# @USAGE: [ignore]
# @DESCRIPTION:
# Takes a list of ignores and creates an argument to be passed to rsync.
_rsync_ignore() {
	local tmp=$(mktemp -t deta)

	for excluded in $1; do
		echo $excluded >> $tmp
	done
	# defer rm $tmp
	echo "--exclude-from=$tmp"
}

# @FUNCTION: _rsync_dryrun
# @USAGE:
# @DESCRIPTION:
# Creates the dryrun argument to be passed to rsync. This function
# has DRYRUN support.
_rsync_dryrun() {
	if [[ $DRYRUN != "n" ]]; then
		echo "--dry-run"
	fi
}
