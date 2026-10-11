# Sourced by run.sh and play.sh: games with C code. A game that has
# native/Makefile gets `make -C native` run in a copy of it before it plays,
# and loads what that builds itself (LuaJIT's FFI, from LÖVE 11.4 on here).
# The version images build LÖVE from source, so they have make and a C
# compiler; on macOS (play.sh --mac) it's the host's.

# build_native GAME NAME [IMAGE]: prints the directory to play. A game without
# native/Makefile is played where it is; one with it is copied into a fresh
# directory under out/ and built there, in IMAGE or else on this machine.
# NAME keeps run.sh's builds and play.sh's apart, so each can clear out its
# own earlier ones while the other is running.
build_native() {
	local game=$1 name=$2 image=${3:-} dest
	if [ ! -f "$game/native/Makefile" ]; then
		echo "$game"
		return 0
	fi
	# A fresh path each time, as in run.sh: Docker Desktop can show a container
	# a stale view of a directory deleted and recreated at the same path.
	mkdir -p "$ROOT/out"
	rm -rf "$ROOT/out/.native-$name".*
	dest=$(mktemp -d "$ROOT/out/.native-$name.XXXXXX")
	# Not what the game's .gitignore leaves out: a build for this machine would
	# look up to date to make in a Linux container.
	rsync -a --exclude .git --filter=':- .gitignore' "$game"/ "$dest/"
	if [ -n "$image" ]; then
		docker run --rm -v "$dest:/work/game" "$image" make -s -C /work/game/native -j4 >&2
	else
		make -s -C "$dest/native" -j4 >&2
	fi || { echo "Building $game/native failed" >&2; return 1; }
	echo "$dest"
}
