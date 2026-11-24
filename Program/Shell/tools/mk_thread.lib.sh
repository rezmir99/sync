# https://www.gnu.org/software/parallel/parallel_tutorial.html
mk_thread() {
local in out command min_line linebuffer ungroup thr_out threads jobs
in=$1; out=$2; command=$3; shift 3

[ -f "$in" ] || { echo "Error: mk_thread: file '$in' not exists" >&2; return 1; }

# configs
min_line=20
#jobs=
[ -z "$thread_max_threads" ] && thread_max_threads=32
[ "$script_diag" = true ] && diag_dir="--tmpdir=$HOME/Process"
if [ "$thread_linebuffer" = true ]; then linebuffer='--linebuffer'; else linebuffer='--ungroup'; fi

# make threads
export thread_dir="$(mktemp -d $diag_dir)"
threads=$(($(wc -l < "$in") / min_line + 1))
[ "$threads" -gt "$thread_max_threads" ] && threads=$thread_max_threads
[ -z "$jobs" ] && jobs=$threads

if [ -f "$out" ]; then
    thr_out="$thread_dir/thr{}.out"
else
    thr_out=$out
fi

sed -i -e '$a\' "$in"
split -d -n l/$threads "$in" "$thread_dir/thr"

# run threads
[ -n "$err" ] && exec 2>> "$err"

parallel $linebuffer --jobs $jobs -q -- ${0##*/} $command "$thread_dir/thr{}" "$thr_out" "$@" ::: $(seq -w 00 $((threads - 1)))

[ -f "$out" ] && merge_files "$thread_dir" "$out" "*.out"

[ "$script_diag" != true ] && rm -rf "$thread_dir"
}

merge_files() {
local name
name=$3
[ -z "$name" ] && name='*'
find "$1/" -type f -name "$name" | sort | xargs -d '\n' -r cat >> "$2"
}
