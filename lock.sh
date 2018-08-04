#!/usr/bin/env bash
# Author: Dolores Portalatin <hello@doloresportalatin.info>
# Dependencies: imagemagick, i3lock-color-git, scrot, wmctrl (optional)
set -o errexit -o noclobber -o nounset

HUE=(-level 0%,100%,0.6)
EFFECT=(-filter Gaussian -resize 20% -define filter:sigma=1.5 -resize 500.5%)
# default system sans-serif font
FONT="$(convert -list font | awk "{ a[NR] = \$2 } /family: $(fc-match sans -f "%{family}\n")/ { print a[NR-1]; exit }")"
IMAGE="$(mktemp).png"
SHOT=(import -window root)
DESKTOP=""

OPTIONS="Options:
    -h, --help       This help menu.

    -d, --desktop    Attempt to minimize all windows before locking.

    -g, --greyscale  Set background to greyscale instead of color.

    -p, --pixelate   Pixelate the background instead of blur, runs faster.

    -f <fontname>, --font <fontname>  Set a custom font.

    -t <text>, --text <text> Set a custom text prompt.

    -l, --listfonts  Display a list of possible fonts for use with -f/--font.
                     Note: this option will not lock the screen, it displays
                     the list and exits immediately.

    --               Must be last option. Set command to use for taking a
                     screenshot. Default is 'import -window root'. Using 'scrot'
                     or 'maim' will increase script speed and allow setting
                     custom flags like having a delay."

# move pipefail down as for some reason "convert -list font" returns 1
set -o pipefail
trap 'rm -f "$IMAGE"' EXIT
TEMP="$(getopt -o :hdpglt:f: -l desktop,help,listfonts,pixelate,greyscale,text:,font: --name "$0" -- "$@")"
eval set -- "$TEMP"

# l10n support
TEXT="Type password to unlock"

while true ; do
    case "$1" in
        -h|--help)
            printf "Usage: $(basename $0) [options]\n\n$OPTIONS\n\n" ; exit 1 ;;
        -d|--desktop) DESKTOP=$(which wmctrl) ; shift ;;
        -g|--greyscale) HUE=(-level 0%,100%,0.6 -set colorspace Gray -separate -average) ; shift ;;
        -p|--pixelate) EFFECT=(-scale 10% -scale 1000%) ; shift ;;
        -f|--font)
            case "$2" in
                "") shift 2 ;;
                *) FONT=$2 ; shift 2 ;;
            esac ;;
        -t|--text) TEXT=$2 ; shift 2 ;;
        -l|--listfonts) convert -list font | awk -F: '/Font: / { print $2 }' | sort -du | ${PAGER:-less} ; exit 0 ;;
        --) shift; SET=true; break ;;
        *) echo "error" ; exit 1 ;;
    esac
done

if "$SET" && [[ $# -gt 0 ]]; then
    SHOT=("$@");
fi

"${SHOT[@]}" "$IMAGE"

# get path where the script is located to find the lock icon
SCRIPTPATH=$(realpath "$0")
SCRIPTPATH=${SCRIPTPATH%/*}

VALUE="60" #brightness value to compare to

COLOR=$(convert "$IMAGE" -gravity center -crop 100x100+0+0 +repage -colorspace hsb \
    -resize 1x1 txt:- | awk -F '[%$]' 'NR==2{gsub(",",""); printf "%.0f\n", $(NF-1)}');

if [ "$COLOR" -gt "$VALUE" ]; then #white background image and black text
    BW="black"
    ICON="$SCRIPTPATH/icons/lockdark.png"
    PARAM=(--textcolor=00000000 --insidecolor=0000001c --ringcolor=0000003e \
        --linecolor=00000000 --keyhlcolor=ffffff80 --ringvercolor=ffffff00 \
        --separatorcolor=22222260 --insidevercolor=ffffff1c \
        --ringwrongcolor=ffffff55 --insidewrongcolor=ffffff1c)
else #black
    BW="white"
    ICON="$SCRIPTPATH/icons/lock.png"
    PARAM=(--textcolor=ffffff00 --insidecolor=ffffff1c --ringcolor=ffffff3e \
        --linecolor=ffffff00 --keyhlcolor=00000080 --ringvercolor=00000000 \
        --separatorcolor=22222260 --insidevercolor=0000001c \
        --ringwrongcolor=00000055 --insidewrongcolor=0000001c)
fi

convert "$IMAGE" "${HUE[@]}" "${EFFECT[@]}" -font "$FONT" -pointsize 26 -fill "$BW" -gravity center \
    -annotate +0+160 "$TEXT" "$IMAGE"

# If invoked with -d/--desktop, we'll attempt to minimize all windows (ie. show
# the desktop) before locking.
${DESKTOP} ${DESKTOP:+-k on}

# try to use a forked version of i3lock with prepared parameters
if ! i3lock -n "${PARAM[@]}" -i "$IMAGE" > /dev/null 2>&1; then
    # We have failed, lets get back to stock one
    i3lock -n -i "$IMAGE"
fi

# As above, if we were passed -d/--desktop, we'll attempt to restore all windows
# after unlocking.
${DESKTOP} ${DESKTOP:+-k off}

