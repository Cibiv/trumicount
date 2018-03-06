# Operating System

# Operating system
MACHINE="$(uname -m)"
OS="$(uname -s)"
case "$OS" in
	Darwin)
		CONDAOS="MacOSX"
		PKGSPECOS="osx"
	;;
	Linux)
		CONDAOS="Linux"
		PKGSPECOS="linux"
	;;
	*)
		CONDAOS="$OS"
		PKGSPECOS="$OS"
	;;
esac

# Version of gwpcR to use
CONDA_VERSION=4.4.10
CONDA_ARCHIVE="Miniconda2-$CONDA_VERSION-$CONDAOS-$MACHINE.sh"
CONDA_DIGEST="Miniconda2-$CONDA_VERSION-$CONDAOS-$MACHINE.sha256"
CONDA_URL="https://repo.continuum.io/miniconda/$CONDA_ARCHIVE"

# Version of gwpcR to use
GWPCR_VERSION=0.9.9
GWPCR_ARCHIVE="gwpcr-v$GWPCR_VERSION.tar.gz"
GWPCR_DIGEST="gwpcr-v$GWPCR_VERSION.sha256"
GWPCR_URL="https://github.com/Cibiv/gwpcR/archive/v$GWPCR_VERSION.tar.gz"

# Test environment package list
TESTENV_PKGS="testenv-$CONDAOS-$MACHINE.pkgs"

# Cache
export CACHE=~/.cache
test -d "$CACHE" || mkdir "$CACHE"

# Directories
export TESTCASES="$TESTS/testcases"
export TRUMICOUNT="$TESTS/../trumicount"

function get_archive() {
	local v_archive="${1}_ARCHIVE"
	local v_digest="${1}_DIGEST"
	local v_url="${1}_URL"
	if test -f "$CACHE/${!v_archive}" && (cd "$CACHE"; shasum -a 256 -c "$TESTS/${!v_digest}"); then
		echo "Found valid ${!v_archive} in cache $CACHE"
	else
		if test -e "$CACHE/${!v_archive}"; then
			echo "Found invalid ${!v_archive} in cache $CACHE, removing it"
			rm "$CACHE/${!v_archive}"
		fi
		echo "Downloading ${!v_archive} from ${!v_url} into cache $CACHE"
		curl --silent --show-error --fail --location -o "${!v_archive}" -L "${!v_url}"
		if ! shasum -a 256 -c "$TESTS/${!v_digest}"; then
			echo "Failed to validate ${!v_archive}, checksum missmatch" >&2
			exit 1
		fi
		echo "Moving ${!v_archive} into cache $CACHE"
		mv "${!v_archive}" "$CACHE/${!v_archive}"
	fi
}
