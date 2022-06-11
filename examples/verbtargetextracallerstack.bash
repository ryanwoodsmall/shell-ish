#!/usr/bin/env bash
#
# generate some functions in "verb_target_extra{_extra,...}" format
#
# XXX - "stack" is not right, need a depth tracking wrapper with a counter for indent level
# XXX - increment n, filter functions and add caller as necessary
# XXX - should verb be action? action-target-options? important!
#
# this can be used to get and use function-name-encoded info with a standarized naming scheme
# - like package name at runtime using function name
# - or "what to do"
# - if this is "install" with "name1", do this, if it's "name2" do this other thing
#
# useful funcs
# - {get,has}{verb,target,extra}
#
# also show caller info and stack here and there
#
# recursion detection - loop too... hmmmmmm...
#
# splicing into functions:
# - "call func args"
# - wrapper, check for flag
# - should probably check that something is actually a function with declare, otherwise just eval?
# - "save old func" should probably save the body only
#   - declare -a newfunc=()
#   - mapfile -t newfunc < <(declare -p func)
#   - unset newfunc[$((${#newfunc[@]}-1))] # delete last '}'
#   - shift # get 'funcname () '
#   - shift # get first '{'
# - probably need a "wrapper wrapper" that just prints the new function with amendments
#   - would allow replacements
#   - func -> newfunc -> func=newfunc -> delete newfunc
#   - with callbacks/callhook below...
#   - could use for e.g. a package to tell upstream "if you install yourself, upgrade me too"
#   - no special handling, just throw a check in a function or an overrides dir that's sourced
# - if flag, save function, insert code...
#   - like to show stack...:
#   - { printf "%$((${#FUNCNAME[@]}*2))s" ; printf " * ${FUNCNAME[0]} : ${@}" ; } 1>&2
#     -or { l=${#FUNCNAME[@]} ; for i in ${!FUNCNAME[@]} ; do e=$(((${i}+1)%${l})) ; printf "%$((${e}*2))s" ; echo "* ${FUNCNAME[${i}]}" ; done ; } | tac 1>&2
#   - "eval newfunc argument1 argument2 ..."
#   - restore oldfunc
#   - delete newfunc
#
# variables and functions can be named the same thing
# - essentially getter/setter/...
# - useful for object oriented stuff?
# - could dump, eval-able var[#]="${v[${n}}" in iteration
# - serialize, deserialize, append, prepend, insert, ...
# - rehydrate self???
#   - save the var with declare -p
#   - then the func with declare -f
#   - store in hash as deserialized object/state/whatever with known keys
#   - type tracking...
#   - for nested types, need type - really only need to handle:
#     - hash  of hashes : hh
#     - hash  of arrays : ha
#     - hash  of values : hv
#     - array of hashes : ah
#     - array of arrays : aa
#     - array of values : av
#       - everything else should be composable
#       - i.e. a hash of hashes of arrays of hashes of an array of values -> hh, ha, ah, ha, av
#       - given a spec: hh[ha[hv[..]]] generate type_..._function automatically
#   - could be a parser/virtual cpu,,, see the mess below
#   - case/esac would be better here but ehhh
#   - pass custom-format storage to function to modify the variable
#     - might need a wrapper to setup type detection/behavior...
#     - recursively iterate through structure and build out state hashes via type information below
#     - track type, depth, ..., via : / , _ separators
#     - "hashname['top']['sub'][#]" hh[ha[av]]] - set/get the element at list position # from within the sub hash, which is in the top hash
#     - "listname[#]['homedir']" ah - given a uid #, get/set the homedir from that accounts stored hash
#   - "varfuncwrapper create varfuncname type/schema array/hash/.../definition function/definition"
#   - hha -> hh[ha[av]] expansion/setup
#   - varfunc has get/set/serialize/deserialize/eval/... by default
#   - base64 encode internally?
# - hmm, little example:
#     #!/usr/bin/env bash
#     # unset varfunc ; unset -f varfunc
#     # { declare -p varfunc ; declare -f varfunc ; } 2>/dev/null
#     # declare -a varfunc=( zero one two )
#     # { declare -p varfunc ; declare -f varfunc ; } 2>/dev/null
#     declare -a varfunc=([0]="zero" [1]="one" [2]="two")
#     function varfunc() {
#       local v=${FUNCNAME[0]}
#       { test $# -eq 0 && cmd=id ; } || { cmd=$1 ; shift ; }
#       { test $cmd == append && while $(test $# -ne 0) ; do eval "${v}+=( \"$1\" )" ; shift ; done ; } \
#       || { test $cmd == serialize && declare -p ${v} ; } \
#       || { test $cmd == id && echo this is $v ; }
#     }
#     # varfunc
#     this is varfunc
#     # varfunc serialize
#     declare -a varfunc=([0]="zero" [1]="one" [2]="two")
#     # varfunc append three
#     # varfunc serialize
#     declare -a varfunc=([0]="zero" [1]="one" [2]="two" [3]="three")
#     # varfunc four five
#     # varfunc serialize
#     declare -a varfunc=([0]="zero" [1]="one" [2]="two" [3]="three")
#     # varfunc append four five
#     # varfunc serialize
#     declare -a varfunc=([0]="zero" [1]="one" [2]="two" [3]="three" [4]="four" [5]="five")
#     # varfunc append "six seven" eight "nine ten"
#     # varfunc serialize
#     declare -a varfunc=([0]="zero" [1]="one" [2]="two" [3]="three" [4]="four" [5]="five" [6]="six seven" [7]="eight" [8]="nine ten")
#
# - could also be used as a recursive/type thing
#   - storage, state, and... other
#   - json, yaml, toml, etc.
#   - building evalable nested data structures
#     - function type_ha_func() { # do something related to a hash of arrays ; }
#     - function type_ah_func() { # ditto for array of hashes ; }
#   - could generate specific datatype functions
#     - function typefuncgen() { type=${1} ; eval "function type_${type}_func() { # ... ; }" ; }
#     - need base (hash, array, value, ...) cases
#     - use a separator (_ or | or : or / or ...) to create nested structures
#       - programming language type stuff...
#       - need a depth marker as well?
#       - h: for hash
#       - a: for array, below?
#         - l: for list?
#         - (evalable? {#..#}/{,}/... notation?! lol!)
#       - d:0 by default
#         - would apply to every element after set
#         - or until parser finds separator
#         - so need to track state/reset for multi-level data
#       - b: for bool flag (true/false is 0/1 in shell?, but should be b:1 if bool, default to b:0 for not)
#       - i: for integer
#         - n: for number
#         - i: for idempotent? r:?
#       - f: float
#       - r: read-only flag
#         - or raw? absolutely need a "just give me the raw representation of this, whatever it is"
#       - w: read/write flag
#       - x: execute ${encodedcommand}, needed in hash-key compat format
#         - c: for "callable"? r/w/x is more understandable
#       - e: ${varname} type to expand an environment variable
#         - (v: varname instead of "variable" in type below?)
#         - thus becoming self aware
#         - could even be _the_ base type
#         - i.e. on recursion/setting/etc. _everything_ is converted to an e:varname type and eval-ed
#         - i just invented something like dumb xml in shell script
#           - programmable since you can just store strings and everything will be eval-ed
#           - very useful! goofy!
#           - basically hungarian notation! but worse.
#       - with (h,a,...) type attached (hash, array guuhhhhhhh value/variable)
#       - create/access/eval hash
#       - ${type}_${name}[(a|h):k(/|_)...]
#         - e.g. a hash of arrays for saving function bodies would be something like
#         - ha_[h:func_a:body]
#         - h:func will be the name of a function
#         - a:body will actually just be iterated over index
#         - equivalent to var[${funcname}][#]
#       - elements can be accessed/set in env this way
#         - ${type}_${name}[h:${key}_a:${index}_...]
#         - use [(a:index0|h:hash0)/h:hash1/hash2/.../(h:hashN|a:indexN)] notation for datatypes
#         - on lookup, if that var doesn't exist, create it
#         - for loading data, have to track depth, which can also be explicitly set via d: below
#       - for storage etc use depth as well
#         - i.e. json, yaml, etc. expansion using types
#         - if a list/array print this header for this format, if header this, bool, etc.
#         - iterate through type/name/depth
#         - enables multiple representations
#           - raw shell - base
#           - json / yaml - storage
#         - requires pretty strict schema
#           - conversions into shell from storage? hard
#           - data not in the schema will be ignored (i.e., no type_######_func) or crash?
#         - if state (functions, values, counters, etc.) can be captured, shell storage could allow full replay
#           - like literally, executable function and data state is interpretable
#           - counters could register themselves as important and saved in state
#           - metadata/state element as well
#           - could send a "backup signal" to dump state...
#           - functions could be marked idempotent in copy/save/restore (or at runtime)
#         - with a parser i could build a language that "compiles to shell"
#           - or a compiler backend...
#           - or an assembler in bash...
#             - printf can write binary data: https://stackoverflow.com/questions/43214001/how-to-write-binary-data-in-bash
#             - instruction type/instruction/... value type/val1/...
#             - instruction hash that stores what to do when called with the data provided
#             - global state tracker, functions save/restore/set as needed
#           - or... an assembler FOR bash
#             - wasm for shell
#             - the shell machine
#             - just implement llvm... vm?
#             - low-level-shell
#             - could build a parser...
#               - character-by-character
#               - tokenize
#               - track depth
#               - store parsed elements w/depth+state
#               - need a simpler format than hash of hash of ... arrays/values
#               - { depth state token previous next }
#
# - virtual machine bit/byte code interpreter
#   - oh lord
#   - all things are possible in parsers
#   - bitness? 8 is minimum _usable_, might be too slow even for that. 32-bit tho...
#   - build a tower of interpreters? i.e., 8-bit machine in posix shell, 16-bit, 32-bit, ...
#   - 8-bit vm -> assembler -> compiler -> 16-bit vm -> assembler -> ...
#   - forth for a stack machine might be the most straightforward (see infinite stacks below, also: openboot?)
#   - get to 16-bit you can port unix+c
#     - gets a pdp-11 cross compiler for free, from there bob's your uncle
#     - could even do tcp protocols "network" with /dev/tcp, and socat for udp (or tun/tap/ptp/... ethernet frames)
#     - in backend, could use openssl, curl, etc. with a socket
#     - then pdp-11 vm
#     - then xv6 vm/port, with cross compilers and networking...
#     - then... repeat with bigger/higher-bit cpus/mems/... until you get to gcc, bsd/linux, etc.
#     - or build a real physical computer from nothing? including an operating system? are you nuts?
#     - forth idea could build a stack machine that hosts itself
#   - heirarchical machine from oisc/one instruction set computer (memory machines/transport triggered) up?
#     - start with a signal (toggle high/low), it feeds/acts as a clock that feeds two clocks (2-bit primitive program counter)
#     - 4-bit, 8-bit, 16-bit, ...
#     - stack/heap growth with big bitness/savvy enough memory model
#     - 8 bit word/byte w/memory machine tied to each address
#     - essentially a distributed set of registers "do something when this happens"
#     - could build a larger cpu with an array of these
#       - assuming we want to build an 8-bit word length
#       - X (2^8 gives us 256 8-bit/1-byte) words wide (essentially every "register" is a memory address), word length plus overhead deep
#       - each "register" (memory element) has (at least) 12+ bits (~16, for bus+overhead) as its control "cpu"
#         - basically, essentially, at least a 4-bit cpu that's a state machine built out of gates
#         - really need sparse array...
#         - packing/padding for 8->16, etc.
#         - could have multiple banks... interrupt, etc.
#         - and/or cascading memory controllers for bitness widening
#           - memory controller controller takes row X and reads word-width columns
#           - memory controller controller reads its own message tag, figures load/store, then reads/writes rows/colums
#           - row-columns made of 256x8-bit bytes (words) of storage per element
#             - equates to 128x16-bit, or 64x32-bit, or 32x64-bit, or...
#           - columns dictate bitness - 16-bit is 2 columns, 32-bit is 4, 64 is 8, ...?
#           - rows dictate amount of total memory?
#             - total: ((2^w)*w) where w is word length
#             - 8-bit: ((2^8)*8) = 256 words of length 8-bit: 2048 (2K), 16-bit: ((2^16)*16) = 1048576 (1M), ...
#           - tricky dealing with bit widths. but "main" cpu will essentially just be bigger version of this
#           - i.e., a direct 16-bit address will have basically 16 probably 5-bit computers
#           - harvard vs von neuman? hmm
#         - memory element just idles normally checking for tags and passing bits
#         - high-level controller isa is basically
#           - load memoryaddress
#           - store number at memoryaddress
#           - to talk to memory elements needs a tag (register) so more state, and a "command"
#           - basically just pushing packets to a queue then popping off on memory
#         - number encoding will need bit # (1-8 / 0-7) so 3 bits (parity not a bad idea?)
#         - memory state:
#           - word (8 bits), tag (3 bits), msg (2 bits?), ready bit, in bit, out bit (16 bits...)
#           - (invisible) readonly flag for r0: always zero
#           - read packet of data
#           - if tag matches act on in bit stream and write to out bit stream (short circuit)
#           - otherwise just write in to out, which is wired up to next tagged memory element via bus
#         - for toggles, just increment since overflow - "declare -i i=0 ; ((i=(i+1)%2))"
#         - memory "register" isa:
#           - ready
#           - idle
#             - or toggle state as 1/0
#             - only allow set tag on not ready/idle
#           - set tag #
#           - set bit # to 0
#           - set bit # to 1
#           - conditional set bit # (0 if set, 1 if not? is toggle?)
#           - toggle bit # (read bit, increment via toggle above, write bit)
#           - 0 all
#           - 1 all
#           - invert
#           - xor
#           - nop
#           - shift left
#           - shift right
#           - read bit / byte / word # (load)
#           - write bit / byte / word # (store)
#         - "bus" related commands - should be covered by read/write but will also need completion acknowledgement
#           - don't need sign (or bcd?) for memory controller/register - it's just storing bits
#           - readbus/writebus handlers - each memory element is essentially a vampire tap that runs a little machine to operate on bits in a word
#           - iterate through stream, checking tag
#           - input/output can be queues
#             - shift off first element
#             - read a "packet" - msg tag, element tag
#             - if not for us, continue
#             - pc here can be 8-bit, 0-255, with second 8-bit map which indicates which memory register tags are in flight 0/1
#             - read tag once, compare per clock, act accordingly (not realistic but faster than reading an entire queue of stuff
#           - check tag - if match, do instruction and ack
#           - reset, acknowledge, resend, etc.
#           - register tags with target in instruction encoding
#           - memory controller sends, register acts, drops response onto bus, controller receives
#           - memory controller state? flag register? ...???
#           - each message also has a tag
#             - how big? just use pc? one instruction per clock?
#             - 3-bits means there could always be something for every address... (i.e. refresh tag# to simulate ddr ;D)
#             - 4-bits means you can do "global" flag - every register should do this
#           - send: memtag#:msgtag#:encodedinstruction
#           - receive: msgtag#:encodedresponse - 11-bits or more
#             - need memtag#? will be "first acknowledged" since we dump to bus
#           - should memory registers be able to latch the bus? "process message # right now (just shift off packet), then unlatch"
#             - essentially locking, would probably need "commands" back to controller in message response, act accordingly in controller
#             - would open up length tag - i.e., start processing and don't stop until you've done X things
#             - memory register arrays would need another pc each, 8-bit, again?
#             - detect tag -> reset memory registry pc -> start counting and pulling packets off bus
#           - controller (and memory registers) need "all tags do this?" (i.e., reset)
#           - memory register tags
#             - id for sending data to byte/register storage machine
#             - memory elements start out in ready state, all tags set to beginning sentinel (0 or 255)
#             - controller drops "tag255:settagto0 wait:tag0 tag0:idle wait:tag0"
#             - repeat for "tag255:settag1 ... tag1:idle ..."
#             - "one at a time" communication on bus - would need a proper protocol for multiplex
#             - controller state needs a bool flag (bit) for zeroed, current message tag, outstanding message, ...
#             - iterate through again zeroing all elements
#         - each of these memory "registers" also has connections to a "bus" - basically input/output (above)
#         - (could do register-register control too, with wide/deep enough bitness and decent protocol)
#         - ipl loads the higher level cpu on the oisc, which is literally just 0/1 gate
#           - it just toggles, basically acting like a clock/oscillator
#           - two downstream oisc using input from clock can create a 2 bit program counter
#           - work your way up to an 8-bit+ pc
#           - at that point you can start using your "memory" registers
#             - do it all again for the cpu to actually use that memory
#             - talking to the memory controller
#             - using another state machine, with another program counter, with a different register set, ...
#             - again, could have 256 8-bit registers but only present #
#             - need sign bit here, ... !
#             - isa is essentially encoded into lower registers - "firmware", "microcode"
#             - instruction dispatch - maps instruction to 1 to ~2+ registers
#             - another "packet" on a bus, this time the tag is the opcode
#             - variable length instructions? nah... wasteful for fixed length but significantly easier
#             - instruction has at least one sorta ghost/window register
#             - isa itself uses "raw" registers (all 256) and designates # of registers
#             - w0-w256 are raw registers
#             - w0:1 - nop (top half of register set for smuggling data?), w2:3 add family, w4:5 jump, branch, ...
#             - r0: always zero, r1-r#: general purpose, ..., what else? look at mips/risc-v/openrisc/...?
#             - state machine control flow uses pc/ip/stack/... for execution
#             - stack grows down from "top (last)" register
#             - heap is separate memory array described above
#           - isa
#             - load / store
#             - add / sub
#             - push / pop
#             - jmp / jne / jz / etc.
#             - cmp / cas / etc.
#             - bra?
#             - mul/div implemented on add/sub?
#             - ... many more
#       - base on 680x/650x (8b data, 16b address)? 8008 (8b,14b)/8080 (8b,16b)? z80 (8b,16b)?
#       - 16b: 65c816 (8b external/16b internal/24b address)? ...
#       - could do abstract stack machine... layer register machine on top...
#       - kinda like the belt cpu?
#       - kinda like the barrel cpu?
#       - kinda like a bitslice cpu? bus status/carry/overflow/next/last/cycle/reset/interrupt/...
#       - kinda like a gate array?
#       - kinda like a bunch of nested gate arrays with a clock driven by a flip-flop - or subleq >;)
#       - kinda like conway's game of life?
#       - kinda like computing from nothing but a switch?
#       - kinda like bootstrapping the universe?
#   - could essentially implement a load/store architecture using depth/state tracking
#   - instruction set... two or three operand... 2 or 3 operand...
#   - calling convention (higher level - callee or caller saves/restores?)
#   - register, memory, opcode dispatch, character display, ... arrays
#   - how many registers?
#   - stacks for each register
#     - or hash of lists for state of registers?
#     - either way a push/pop to save state is relatively easy
#       - would need to do a copy for something like this to work
#       - save: for r in ${!register[@]} ; do r[${#r[@]}]="${r[$((${r[${#r[@]}-1))]}" ; done
#       - restore: for r in ${!register[@]} ; do unset r[${#r[$((${#r[@]}-1))]}] ; done
#       - would need a state tracker here too - a counter? latching?
#       - serialize register set, push, increment / pop, deseralize, decrement?
#       - "infinite stack"
#         - stack pointer, basically
#         - save: copy the top # elements to end of list, increment counter
#         - restore: remove last # elements of list, decrement counter
#       - could combine these to have multiple processor states...
#         - could essentially build another level of processer directly in ISA
#         - i.e. 2x8-bit states and mux/carry/etc. flags could allow for a 16-bit alu
#         - overflow/carry/etc. trigger state swap
#         - bitslice idea all over again
#           - memory bank... internal and external busses
#           - internal bus is tag:message:opcode in/message:signal (flags) back to mc
#           - external bus - propagate carry/remainder/overflow
#           - 256x8 (2KB) could be wired up serially to
#           - dual port? memory controller per bank with go/nop flag
#           - pause downstreams as control is transfered between banks
#           - memory controller controller reads external bus and directs traffic from bank to bank based on state
#   - clock, program counter, stack, stack pointer, instruction pointer, interrupts, ...
#   - overflow detection, remainder, etc.
#     - test "${register[r#]}" -gt 255 # overflow detected; interrupt, etc.
#     - $((${register[r#]}%256)) # remainder, set flag, etc.
#   - queue for instructions?
#   - host/vm socket communication: at least stdin/stdout/stderr; need bidirectional multiplexed?
#   - could "freeze" whole machine using state stuff above
#   - like... save the vm program itself along with state, it's literally a shell script
#   - could keep a bit of program counter history to read the next instruction, rollback and dump
#   - "memory pointers" et al for indirection/instruction set/memory model
#     - i.e. one level of indirection: "load what is at the memory address in memory[#] into register[#]"
#     - "load what's on top of stack into register[#]" or "memory[#]" or "register-to-register" or "stack into memory at address stored at memory[#]"
#     - "load r1,r2" register-register; "load si,r3" stack indirect, "store mi,st" memory indirect to top of stack; ...
#     - load relative to r#/m#/...?
#   - memory... byte addressed or word addressed (or both, byte@ is splice into word@, halfword for 16-bit+?) or bit addressed or linear or...
#   - memory protection/mmu? tagged, content-addressible, ... memory? whoa
#     - memory register windows w/content-addressible - give me byte @ #, two bytes (16-bit word) at ##, 32-bit word at ####, ...
#     - word, halfword, nibble, byte, long, long long, ...
#   - endianness???
#   - pause machine (background lol)
#   - debug/monitor - eval individual instructions
#     - pause / single step / etc.
#     - register/stack/pc display
#   - small virtual assembly language for main cpu
#   - "enough for c"
#   - assembler first
#   - output stuff to console, that's it, branch forever, etc.
#   - linker/loader. boyyyyyyy.
#   - intermediate languages...
#   - work up to c...
#   - c compiler targeting virtual assembly
#   - forth (eforth on subleq?) first???
#   - notes on notes on notes
#     - "dump state" for image is very lisp-y
#     - boiling the oceans
#     - for copying functions/serializing, a `${#}` file descriptor can be opened read/write for reliable/safe eval/apply?
#       - nested locks (stack) - no loops? dag?
#     - might be easier than while/printf. and cleaner
#     - bash has readonly function/variables, and they can be the same name...
#     - a little oo but opens up a path to more structured datatypes/operations
#       - could easily do a "super func" root object on create/copy, i.e.:
#         - if `${FUNCNAME[0]}` is `main` or %{rootuuid:-0} we're the root/base Object object
#         - `@{operator[/path/to/...]}` - below
#         - configurable `${rootobject}` variable... multiple environments
#         - objects nested have an id - base64 of type/element/permission with grouping? - that is in the "root" hash (r/o id "0")
#         - objects need a parent id - root will be itself (0), acts as a dispatcher (just `eval "${@}"?)
#         - each object has a global uuid -> full path map; create on access of empty element, generate uuid, lock pathmap for w, save %{pathmap{%uuid}}, unlock pathmap
#           - each object has a global uuid -> full path map (hashed, see hashid); create on access of empty element, generate uuid, lock pathmap for w, save %{pathmap{%uuid}}, unlock pathmap
#         - ... need good hash locking setup too... - gotta be a counter if multi-threaded/multi-process - if unlocked, take lock ( wait lock , lock, run, unlock )
#         - could be used as... get this: pointers
#         - have to check if you're the "last" - i.e. is my value less than top-of-stack, unlock and try again - cooperative... at best, could be a nightmare...
#         - what am i building here, an abstract symbolic representation of a stack machine??? that i can implement a register machine/vm on??? whaaaaaa?????
#         - objects need a symbolic name - `root` or `main` for the root - mark default `eval` function wrapper read-only
#         - objects need a name - `root` or `main` for the root - mark default root `eval` function wrapper read-only
#         - stack of parent id - creating a computer again
#         - parent needs a list of all its children (directory entries/virtualvars/by type!)
#         - every child with $(hashid) is in a subdirectory called `children`
#         - nested lists that eventually just `printf` or `eval` themselves? - with types!
#         - root would only ever exec, so would `exec exec ...` or `exec printf "${value}\n"` based on leaf type information
#         - references would just `eval printf $(their own value)`
#         - you just invented a lisp computer, player!
#           - macro types: save/eval "raw" unescaped metalanguage/vars w/stdin, or fork a shell process off and `exec` leaf (bin) w/stdin?
#           - would need wait flag for fork... "threads"
#           - fork / exec with tini either in foreground or backgroup to reparent and reap children?
#         - stack pointer, stack, etc. - `declare -a object_stack` - "top" will be "${#-2}" instead of -1
#         - can jump to/rewind the stack by grabbing up to ${elements}, pushing those and jumping - eval/printf/exec based on tape
#         - (would allow an iterator, and really need a counter anyway - could be a "type" to track state, and track "last updated"/timestamp in metadata and/or outside of fs
#         - detect depth and `goto` or just `exec` the previous to replace current environment when you hit the root element?
#         - `pushd` & `popd` - create fs snapshots with some hash/list/leaf value - nested, structured, save readability via below
#         - `push` & `pop` - queue - lifo - ordered list
#           - `shift`/`unshift` - same but stack - fifo - ordered list
#         - `exec` or `run` to run (eval) whatever whatever is at value
#         - variable substitutions "%{var}" & "%{var[%{index}]}: (and "%{instructionpointer}" "%{stackid}" "%{stackpointer}" "%{stack[%{stackid}]}=[]")
#         - flags like %{readonly}, etc. (per-var? %{readonly[%{var}]}?) - both, by name with typeinfo
#         - could add "signature"/encryption+flag and store in the versioned metadata w/public key id used for encrypting/verification, later decrypting with private key
#         - and private key id/path for automatic decryption... (special keys, sig, etc. flags?)
#         - versioned along with everything else...
#         - things can only be "jump"-ed, printed, eval-ed, stored, deleted, have key set to value (and capture type), etc.
#         - designate "special" type for `%{var}` designating function...
#         - if function, eval that stored at `%{fullpathto%{var}[%{var}]}` with stdin
#         - func: function, evaluates against stdin; list: (specific) raw bash list; hash/array: raw bash hash; var
#         - `type`/`istype` command/var - return type of %{var}, true (0) whether it is matching 'type:[type:[type:[%{type]]]', otherwise no (1)
#         - `state`/`updated` - global and obj level - command/var : toggle-able var that indicates if var has changed - set on access; return 1 if dne; otherwise read into var and return 0
#         - recursive?!?!? flip need write bit to for ancestors
#         - `sync`: write whats in memory as changed, creating on disk what's in memory (serialized, encoded, etc.)
#         - starting at deepest leaves, writelock/create+withlock+writelock uuid/path, commit metadata (versioned?)
#         - `@{{action|value}{|[%{selector}]}[%{index}]}` - "language" constructs expanded to bash evalables - map to virtual syscalls
#           - dup, etc.: https://man7.org/linux/man-pages/man2/open.2.html#SEE_ALSO
#         - ex:
#         ` ```
#           object sandwich {
#             toggle:[|path/]sounds:[true|false]
#             func:toggle {
#               local %{boolalias['good','bad']}
#               local %{boolmap[@{value[%{
#               local %{true}=%{boolalias[0]}
#               local %{false}=%{boolalias[1]}
#               printf %{var[%{sounds}|-%{true}]} # default/executable/... type??? tracking too
#               %{v}=%{var[%{sounds}]}
#               %{var:sounds}?%{false}:%{true};
#               printf %{v}
#               %{v}?
#               ...
#           }
#           ```
#         - `known`: check if thing exists, 0 for yes, 1 for no - check memory dirty/marker for uuid; and if exists, say yes
#         - objects can register themselves with a deleteable `new`-like function that is run on inception (locking///////)
#         - reference counting too... on inception of path, backtrack, checking existence, marking dirty, etc. bump reference counter
#         - when something is set/created/etc: lock, mark its global state hash value as dirty, create/stub/set object accordingly, toggle dirty states, unlock
#         - ```
#           objctrl [-d(default:${objectroot:="${HOME}/.object/root"}|-o fullpathtoobjstorage]
#             [type|[known|exists]|[[-|mark]|[dirty|clean]]|ls|cat|cp|mv|rm|eval|[[-|sym]|hard]link|creat|touch|open[[-|rw]|r|w]|close|read|write|lock|unlock|[in|de][|cement]|[|un]mount|-(default:read:stdin)]
#               [[[full|rela|path]|-(default:write:stdout)] [--(stop parsing)|] [args]]
#           # if positional parameter 1 is - (action) will be read from stdin; otherwise action=${1}; shift
#           # if positional parameter 1 is - (path) will be read from stdin; otherwise path=${i}; shift
#           # if positional parameter 1 is -- (args) will be passed througn from stdin?
#           ```
#         - `object "/path/.../leaf" [action] [arguments]` wrapper - "realpath"/"hash"/"expand"/..., read from stdin, write to stdout, save state of hashid
#         - xargs/eval-ish: /full/path
#         - have to track current open r/w flags
#         - can store "root" path as real location in filesystem - by default, like `~/.object/root` and fs is "virtual"
#         - (shard - another level - hash sub "root" objects to a key, using shard controller map, hook eval-able syscalls to convert full path to compute shard hash, build full path)
#         - each shard gets its own
#         - root is not "derefernced" - if ${PWD} is in %{fullpath} -
#         - full path stack for easy deref...
#         - (... inheritance? no? okay)
#         - (tmp stacks serialized to stacks and save/restore on jump...)
#         - types:
#           - uuid: own id (0 for root-root)
#           - parent: id (uuid of parent) (0 for root-root); enum/list beyond root? [root:[-0|:uuid][-|:uuid][[-|:uuid[-|:uuid[...]]]]]
#           - path: own full path
#           - tombstone:(true|false)  - check self state recursively - if parent have a tombstone, toggle bool
#           - tombstone[uuid] "bool map" and uuidtotombbstomb[uuid] to check?
#           - hashid: recursive calculated aggregate hash to 0 (or %{rootuid} if not 0)
#             - eval hashid="$(hashalg %{uuid}:[%{parent}:[ ... [%{parent}:[[%{parent}:[%{rootuuid}]]]]...]])"
#               - if parents was a list, could also encode reachability info...
#               - i.e., recursively for each parent down to %{rootuuid}, chase uuid->parent.uuid->...->rootuuid/0
#               - on rm, make parents list (or stack?) [] (or just parents=uuid -> hashid==uuid: no parents - dead leaf)
#               - cascade???
#               - search for any dangling references to the uuid->hashid map; mark with tombstone/unreachable
#               - depth-first - crawl into deepest heirarchy, check recursively if parent.uuid==parent.hashid until you hit root
#               - recursively set all hashids of any dependent paths to uuid to "cut them off" and mark tombstone in object storage
#               - mvcc/transactions/...
#               - if parent.hashid==parent.uuid&&parent.hashid!=root.uuid->terminal/unreachble/mark tombstone, set hashid->uuid/uuid->hashid maps to uuid
#               - (((uuid==hashid)&&(hashid==rootuid)&&(rootuuid!=[0|rw-/protectedroot])))&&reachable||unreachable
#               - can reconstrcuct paths from actual fs paths, i.e., hashid->path/path->hashid map
#               - find all metadata objects in store, determine if tombstone, ressurect by removing tombstone(s) recursively
#               - can freeze/unfreeze (makero/makerw)+tombstone state this way as well
#               - recursive "copy" of frozen objects to new name in store - freeze, snap to a diff name, unfreeze
#               - garbage[uuid]=(true|false) - bool - if true, trace to root and mark full depth of uuid w/tombstone+depth+...
#               - garbage[path]=(true|false) - bool - if true, check leaf @ path, trace to root and mark full depth of uuid w/tombstone until non-tombstone parent is found
#           - root: (real/full?) fs path of object store (can pushd/popd into virtuals for relative paths!)
#           - rootuuid: by defualt "0", can set to a specific %{parent}:%{uuid} to alter paths
#           - roottype: object/fs/remote/distribution/...
#           - uri: a locator with types+subpaths all reified - use root+roottype+rootuid to figure out mount/namespace/leafs/leafstatus/reachability/dereferencing/... etc.
#           - children: list of child uuids+computed hashid?
#             - `[/full/path/to/uuid]/children/[uuid]/[type]/[k,v]` - in memory [t:[k,v]] - recursive reification/map of/to/... contents
#             - `[t:[k,v]]` defaults to hash of k at /full/path/to/parent/children/type/[k]/[v]
#             - nested... would allow iterables - auto counters
#             - full path is made from concatentating uuids together, hashing, prepending type: - > [type:[[type:[[key,value]|[list]|value][value]]]:[[key,value]|[list]|[value]]]
#             - hashid in {sub-}children: loop/cycle/...
#           - raw: cat whatever's in path - [exist&&notdirty: lock,cat,unlock] || [[exist&&dirty||dne]:lock,rewrite,togglestate,cat,unlock]
#             - basically open/read/write/{un,}lock/close/creat/delete/eval for others w/stdin and proper dispatch based on type...
#             - including binary data!
#             - wrapper: default is basically func: type with 'sh -c "cat %{raw[%{uuid}]}"' with full reification/derefence - and store actually data in content.raw
#           - file: literal file contents stored at $(reifiedpath)
#           - fd: file descriptor (and/or fh: file handle)
#             - fdstack[#]
#             - need state - only 255 fds - if overflow push fd:/path/to/../file onto stack, close fd (write/seralize/etc), openfd pointing at new file read/write/etc.
#             - stdin/stdout always wired up
#             - fdstack pointer -> uuid?
#           - prog: run $(reifiedpath) with stdin+arguments: ( bash -c "$(reifiedpath) "${@}" < /dev/stdin )
#             - process args until -- or ${@} exausted, then read stdin
#           - bin: "binary data" - encoded?
#             - exe:[-|raw:[-|interpreter]] - "raw" flag - use file descriptor? fd table/stack...? at object?; preface with "interpretter" - i.e., "bash -c", "ld.so", ...
#           - keys: list of keys at path - if [k,v], provide k, if [] provided list of indexes, if v printf "%{path}=%{path[%{fullpath}]}" (feasible? dynamic?)
#           - type: have to know own "leaf" type to know how to behave...; if parent.uuid==rootuuid&&hashid!==(uuid/sentinel)
#             - ultimate "leaf" type is always [k,v] map ([:] in groovy!) or [] ordered list or expandable agregate? [::] for type:key:value shortcut?
#             - as always, nest; can use [type:k2:[type:k1:[[type:k0:v0]]]] for "executables" etc.
#             - need a "terminal" marker - depth, unkown, tombstone, etc.
#             - /root/[{type}:hashed{uuid}] -> /root/hashed{uuid}/[type]/[key]/.../[value] - et each level...
#             - with "type inference" - i.e., "i'm type X, i'm going to do either eval or printf" on refernce/lookup
#             - "overload": unbounded/unsigned list ++ increments, -- decrements, ...
#             - like lua tables, kinda?
#           - latch: - callback list to set something on exec, unset on finish (lock: bus, singleton, semaphore, inc/dec counter,...) ['pre','post']
#           - lock: - set un-/locked flag on path?
#           - expr: bash math expression with %{v} and %{v}
#           - {eval,exec}{{,cmd},{map,array,hash},list}: properly type-eval or fork/exec? whatever is stored at path
#           - jump: - jump:[[-|pc]|sp|ip][-|:conditional] save stack(s) and eval indrect value at $target
#           - value: printf "%{path[...]}"
#           - fsloc: print evalable full path, doing shard/encoding/etc. resolution in-flight - needs a "full path reifier!"; reify state recursively
#             - symlinks+fsloc allow sort of namespaces; an object store is "rooted" somwhere and symlinks can be recursively nested w/type???
#             - an object store root can be a "namespace" - another object store root id 0, parent id/fullpath/uuid/etc. set accordingly
#             - all paths must be reifiable to a parseable path: type+value; sy
#           - list: bash list, evalable
#           - hash/array: same, bash hash/associative array, properly quoted
#           - enum: (evalable #-indexed hash with sub expansion/eval/display/... - preserve order, essentially a list with magic
#           - {sym,}link: symbolic link to path - if a symlink type is detected, exec/pushd/popd/etc as appropriate from proper path
#           - hardlink: hard link: full path to item's content
#           - mount: (virtual?) namespace/filesystem/etc. at path - new "root" object symlinked to {shard,distribution}{fullpath|-root}
#           - remote: eval a call to a remote server (remote:[uri|schema|...]:[[[[-|user|key][-|:[pass|keyid]]]@]host[${defaultport}|:port]:/path/to/...]) - default is `file:///`, `fs:///...`
#           - reified: could lookup/eval path inside to out to substitute public/privage key ids, encryption, encoding, etc, to obtain a full uuid -> reified path map
#           - func: eval the function with name using stdin
#           - epoch: 64-bit (signed) seconds since 19700101000000
#           - date: current date? nice representation with flag? formatting? set access/modify timestamps?
#           - offset: local time (utc[+|-]) offset
#           - clock: (just a counter with with fullparentpath/global and optional divider...)
#           - counter:[fullparentpath|global]:divider: figure out parent counter, creating one in lockstep with the current pc (default divider of 1) and loops around by default
#             - ```
#               increment() {
#                 local -i m=1
#                 # stored: counter[@{reified[/path/to/...][-:divider]}]
#                 # passed what? ${current} ${divider} ${parent} ${depth} ...????
#                 # if there's a parent !global, tick that, recursively
#                 # if there's no parent in parent, just bump to ${pc}[:${divider}], then bump counter to value of "anonymous"/pc counter mod 1 or divider
#                 if [[ ${#} -ge 2 ]] ; then
#                   m=${2}
#                 fi
#                 checkorcreatecounter "${1}" &>/dev/null
#                 local -i n=$(getcounter "${1}")
#                 ((n++))
#                 eval export "declare -i counter["${1}:[-|parent:...]${m}"]=$((${n}%${m}))"
#               }
#               ```
#           - signedcounter: hash of [{{,+},-}#]=val
#           - trigger: increment counter/eval something on access - increment/decrement could auto trigger parents to root, then trigger any children with triggers
#             - automatic reference counting...
#             - automatic toggle firing... - per object flip-flop...
#           - table: {func,var,type,object,generic} tables - map path to path of given type - lua, again
#           - state: toggle for object(:this or .this?)/leaf ['clean','dirty'] - find dirty leaves, mark parents dirty recursively
#           - write data+toggle leaf clean, repeat for all leaves, when object has no dirty leaves, mark clean
#           - toggle: toggle:name[:true[:false]] - alternate between true/false or two custom values
#           - archive: archive representation - archive:[[-|tar]|[cpio|pluggable]][:false|autoextractbool]
#             - default to tar; on write, stream stdin to 'tar -cvf $(reifiedpath) - 1>&2'; capture stdout to a list and return serialization...
#             - read to from file to stdout via 'tar -xf - < $(reified path)'
#           - lifo: and fifo:
#             - queue: ordered [] list - fifo - enqueue (push on end), dequeue (shift off front), shift # (shift # number off front)
#             - stack: orderd [] list - lifo - push/pop/shift #: (for i in $(seq ${#[@]} -1 0) { if (( ((${i}-1)) == 0)) ; then break ; else eval "a[${i}]="${a[$((${i}-1))]}" ; fi ; a[0]="${@}")
#             - peak: poke: insert: delete: - look/set/... value in list
#             - apply stack/queue - canonicalize from different ends
#           - register:[-|indirectflag] - yeah - either get a value or eval the value stored in register
#           - mem: "binary memory?" - serialized state? w/type?
#           - ref: jump to seralized mem?
#           - literal: text stored unparsed "eval" for macro
#           - macro: literal: to eval w/stdin
#           - serialize: special trigger; save all leaves w/full paths to their place in the object store and return canonical "/path/to/item/[key,index,var,func,...]=val" to stdout
#           - deserial: oppsoite trigger - read stdin and set path to val - rebuild uuid<->hashid mappings, instantiate in memory
#             - out: all reachable... serialize; not reachable, tombstone
#             - in: set reachable on value, then trace parent back top stored "rootuuid" marking every step on the path reachable
#           - body: recursively serialize into object hash with state
#           - {json,yaml,toml,...}: structured version of searlized data; find reachable leaves, get uuid+hashid, seralize; what clarity? yaml :|, json "\n" escapes, ...
#           - env: hash of ( ['ENVVAR1']="val1", ['ENVVAR2']="val2", ... ) - inherit _this_, may be easier? `pushenv`, `withenv`,... - deference recurisevely?
#         - derferencing uuid or hashid - deref[hashid[hash]]=uuid, deref[uuid]=hashid - bidirectoinal map?
#         - chef habitat's config endpoints consume toml and emit json(/yaml/toml/...) - could heirarchical store state/counters/locks/... with something similar
#           - special flag vals in health (ok/critical/unknown/...|good/overflow/bad/missing/...) for serilized state and key/val/... in config
#           - serialize to filesystem - remote interface... via toml+json+rest+curl+jq+...
#           - `hab file upload ...` for state+service groups+organizations
#           - steal butterfly (swim?), incarnation, health/config endpoints, etc.
#         - "link" functions - alias key in "source[sub[sub[to]]]" to something like `eval @{value[path[to[functin[type[element]]]]]}` - dispatch in root object handler
#         - can essentially return (printf $(reifiedpath) || eval $(reifiedpath) || exec $(reifiedpath) and status
#         - opens up `objalias`: `eval`/`print` element w/stdin (depending on type) creating stubs as needed
#         - (deep copy - a "copy" just just store a jump ref:uuid? on write, allocate new storage and update links
#         - (copy-on-write here could be an object flag... - version your self to "latest" _or_ stored timestamp when you're told to save/serialize/...)
#         - individual file snapshots - `content{,.meta,.children/incoming}{,.tombstone}`
#         - could branch at snapshots, or create a new environment at `%{stack}` with `@{reachability[%{path}]}` using sym/hardlinks
#         - linear, "just" create a hardlink to the other object in the other environment
#         - "easy" copy-on-write - add/del reads old content, pointed to by symlink, changes/exec/outputs/etc. to new datafile, update symlink
#         - read "content.base" -> modify -> write "content.%{ts}" -> update "content" symlink
#         - could also generate diffs, encode timestamps+parent in metadata, "replay diffs"
#         - on quiesce/unsnap/popd/... copy current "$(realpath content)" to "content.base and update symlink
#         - could further timestamp ("content.meta.timestamp" file with state!!!)
#         - multiple versions of content prefixed with `@{time{path[to[item[element]]]}}` or postfixed with stored `%{ts}`
#         - `fork` command that forks/execs whatever is at path[to[...]] with stdin - wait/no wait flag fog &/wait()/etc.
#         - `map` type that returns data in raw bash hash map that can be `declare -A varname=...`
#         - `toggle` type+function/command that checks if null and sets rc to 'shell true' (0) if not set, other wise %{var%%!1}, save state
#         - `encode`/`decode` command/type - receive raw data, convert to textual format (base64?), and store, with encoding type
#         - encoding hook with like `{en,de}code{,:type}` with a hook to run default encode routine
#         - override default encode with, custom scheme falling back to base64? could combine schemes/overrides/specialization for encrypt+signed+encoded content
#         - could do at least semi-efficient "stacks of diffs" for content to rollback/forward
#         - flip-flop, combine with counter that starts at 0 and goes up indefinitely, OR bounded by an optional max
#         - per-object counter and global/root counter+timers - per "tick" (full "instruction"/eval) increment global program counter
#         - object counters would need to be "registered" globally with an optional divider (%%?)
#         - counters are essentially stacks: when (clamped!!!) global overflow is detected, reset the stack to 0, and any global counters that aren't specifically clamped to 0
#         - eval the "root" object, reset any global timers, do recursively (callbacks...)
#         - actually pre-/post- evalers - act on detected type, using object[hashid][hash,func,var,listindex,...] tables for dispatch w/type info
#         - could have a creation timestamp and an "epoch" counter w/nanosecond resolution - cron/schedeuler like setup to eval "if now > {%{diff} %% something}!!
#         - indirect clocks - fire (send interrupt when reset) by eval-ing whatever is at passed stdin - need type here too, for nested
#         - register a clock with `root:[name[:name[|:divider]]]` and check/increment object clocks
#         - with reflection, objects could each have their own stack... micro programs
#         - image debug save could literally restore entire set of stacks/clocks/timers then jump into debug and wait for command (continue/eximine/...)
#         - save debug info `set -x ; exec 2>>${object}_debug.out`
#         - save session info by tee-ing input from the command processor, rlwrapped... paren/brace/bracket matching in interactive console...
#         - use HISTFILE/HISTSIZE/HISTFILESIZE for transcripts/playback/...???
#         - with transaction logs and reachability status, could store essentially "any given state"
#         - full call graphs could be generated in debug...
#         - type plugins... - encrypted files, signing keys, ...
#         - keys _must_ be bash naming compatible if proper i/o between the two, but base64 is ugly...
#         - (storage) everything is a path/.../k/children/v, dir - content in `content` file
#         - name, full path, parent id, child ids, update state flag? stored in `content.meta.XXX` - structured format... json, toml, yaml, ... ???
#         - becomes a virtual object store at that point...
#         - a programmable object store. interactive. dude.
#         - ABSOLUTELY need tombstones - `content.tombstone`
#         - saveable stack - basically a transaction log of how we got to now
#         - snapshot: rewind, append to function run it again, then jump to self...
#         - can then basically crawl the filesystem and go until you see a tombstone, etc.
#         - `move` or `copy` (or 'load'/'store'...) - essentially copy whatever at "${source}" to "${target}", preserving state/creating paths as necessary
#         - `findable at [reference [ reference ...]] %{stackid}` ... - read children
#         - mark all stack ids unreachable...
#         - keep a stack id directory with "reachable" by starting at all reachable children (subdir/subdir/subdir/content) and working backwards
#         - mark each parent unreachable and do it again until only root and leaf are reachable
#         - mark every path to every leaf reachable
#         - cull any unreachable
#         - capturing stack pointer and "next" is important for speedup on state import
#         - parent id could be manually set, so need incoming ids in structured format
#         - object id (sha-256 is sounding better) everywhere.. `content.tombstone` will need to be an ordered list
#         - need depth tracking - need jump...
#         - all but leaf elements (functions/methods, instance members) will be a reference
#           - leaf elements - special treatment? or `eval printf ${objecthash[${objecthashid}]}`
#           - actual nesting too? `${rootobject[${sub[${subsub[${subsubub[${index/key}]}]}]}]}`
#           - add an `o` object type to `h`/`a`/`f` hash/array/function key "language"
#         - access will dereference - hard? lol, yes
#         - mark the source function readonly since it has delegates
#         - create from stub/copy the source function to the target function
#         - prepend the new function with `super=${sourcefunction}`
#         - append the new function with `eval "${super}" "${@}"
#         - "garbage collection" - remove any references that are no longer reachable from root; tombstones?
#     - i.e., noted elsewhere but for "object" as the name of a function/variable, have getters/setters
#     - when items can serialize themself... "objects" could be nested, i.e. a hash of hashes of arrays of...
#     - and accessed via `varname "['hashkey'][#]'"` - default get, with `get`, `set` and `eval` (`add`? `del`? types?) as reserved words
#     - need a permission marker too... `makero`/`makerw` - `:{r,w}`
#     - `add type "name" "definition'` / `del "definition"` list/array, hash, function/callable, item/element/var object (nesting!)
#     - one argument is just `get` on the value at (sub-(sub-(...)))hash/array
#     - two or more is eval
#     - types types types - per hash idea above `object[{type}:{element}{permission}_{t}:{e}:{p}_...]`
#     - depth marker again... grouping w/`{`/'`}` should work with hash keys
#     - `nexthashid` - lockable placeholder? - empty string by default? save uuid to nexthashid, w/lock, then save hashid[uuid]=$(hashid uuid), generate new nexthashid
#       - collision checking! if exists and not tombstone, it's reachable, so overwrite; if doesn't exist/tombsone, check freeze state and either
#       - ... replace/mark reachable/return success if not (dne|tombstone)&!frozen; return error if frozen tombstone
#       - force flag - unfreeze, overwrite, mark reachable, ...
#       - this is all stack handling...
#     - async/sync flag - flush immediately or mark dirty until sync/sweep/access/write/delete/...
#       - crud... transactions... again
#       - arbitrary stacks - get id for next, push on end, ...
#     - lookup formats?
#       - `["[root[hashname[hashname[listname[${index}]]]]]"]`
#       - `["object[object[key][key][key|list]]"]`
#       - `["object.key.[object.key.key.list].key.list.func()..."]` - this one might be HARD
#       - ... but with var+func same named, prepended with TYPE, the evaluator can just figure out what to do
#       - `/path/to/subdir/...` - check type and act (dispatch/eval w/stdin); unpack arrays (hashes!) with '[...]', '[@]', etc...
#       - ... i.e if `...[ [ [ []]]` and/or `...[][]` - convert to canonical form and set up reference
#         - '/path/to/sub/subsub/.../leaf' - w/type info is canonical; looks like fs
#       - add a debug var/macro/flag, it's just a "start at root, jump through stack from start until "next" (last item in ${#[@]} format) is seen
#       - set some debug flags, run it, do some debug stuff (break into set -x session?) then quit
#       - need a hash of lists for "what's in-flight in this state?"
#       - would essentially say "this is the current state of value at the current object"
#       - with explicit func VERSIONING - snapshot/substitute/version entire system... man
#       - var names can can be dereferenced with `declare -n` - setup stack and run `exec ${indirect}`
#       - all just keys
#     - flag to sync on pc overflow (recursive, slow - every uuid that's marked dirty, start at leaf and commit parent until %{rootuuid})
#     - removing readonly elements...
#       - gdb for state/memory access lol https://stackoverflow.com/questions/17397069/unset-readonly-variable-in-bash
#     - `new object`/`object new` - "enter" something that just evals - gets an id, etc., keeping track of type and depth
#     - `enter`/`exit` an object - `begin`/`commit`/`rollback` as well - transactions with `object value "value"`
#     - `object get/show "path[to[node]]"` - show **['key1','key2','key3',...']** or **${value}** at requested level
#     - functions just get automatically called?
#     - lists can have first ${l[0]}, last ${l[$((${#l[@]}-1))]}, top (pushable) ${l[${#l[@]}]}='' accessors
#     - need a function marker too! `:c` (callable? not enough letters)
#     - would need to track read/write status (parser/macro helper) for serialization
#     - upon entry/exit acting on a temp array/hash, the previous temp value is deserialized+pushed/popped+eval on a stack
#     - `declare -I` to copy from a var at the previous scope to a var at the current one
#       - inheritance. again. force/exec...
#     - `type -t` to test if something is a function/alias/command/file/etc. (some `declare -f/-F` overlap)
#       - if not "executable" via type -t, figure out
#     - "readonly[{key,index,var,func,...}[path]]" - hash of read-only paths, based on type; each k can be a key/list index/var/func/...
#       - keep track of var+key/listindex/... type and readonly the hashid
#     - serialized state would require a recursive dump, thus reachability
#     - state could just be a sourceable `.object/environment.bash_object` filesystem file
#     - hook profile/shrc ; hook `eval` evaluator for ticks/clocks/timers/counters - read input, reify, hash, eval with type determinmation...
#     - snapshot would dump a serialization of all the registered objects (can ignore "anonymous" ones?) to file
#     - finally... when objects can serialize themselves, the whole state can be preserved
#     - eval on startup, serialize on shutdown. bang, you have a computer with saved states
#     - bash has a parsing flag to interpret symbols like "$" or not, we'd need something similar for macro creation
#     - basically like every programming lexer/parser/compiler/shell/... but very much lisp/scheme
#     - "flip-flop" toggle drives X-bit global clock that drives program counter
#       - global clock is just a bunch of serial i/o flip flops on a bus that detect overflow and reset to 0 if ${MAXPC} reached
#       - reset signal: set to zero and send off to flip flop array counting up...
#       - 1/0 -> [1/0,1/0,1/0,..,n] -> ...: [0|1]->[[0|1]|[[0|1]|[[[0|1]|[[0|1]|[0|1]]]]]] ... msb/lsb. mested. etc.
#     - type coercion - k,v/list/var/... - any value can trigger like named function at same path with type, depth, value of self? changing type as needed
#       - reflection w/getdepth() parsing path
#       - is this mongo or redis?
#
# - callbacks?
#   - crosware...
#   - "applycallback func" - reify funcs after round of sourcing profile
#   - use a stack/array?
#     - global hash with serialized array of callbacks?
#       - "addcallback func 'cmd one' 'cmd two'"
#       - crosware rcallbacks=( "targetfunc 'cmd1 ; cmd2' 'second set'" "targetgfunc2 'cmd3 | cmd4'" )
#       - serialze original function to a function hash (once, based on hash key existence)
#       - check hash keys for func, initialize to empty array () if not found
#       - if found, rehydrate to temp array
#       - append any args to the array
#       - serialize and save to hash value for func key
#       - rehydrate serialized original func and append all callbacks to array
#       - eval the new function array to replace it
#   - "callback 'callback_def callback_args' func func_arg1 'func_arg2-a func_arg2-b' func_arg..."
#   - shift off callback
#   - save function
#   - insert depth tracker above
#   - replace last element with "callback_def callback args"
#   - "eval newfunc func_arg1 'func_arg2-a func_arg2-b' func_arg..."
#   - restore oldfunc
#   - delete newfunc
# - call should not call itself
#   - if function is call just, eval "${@}"
#   - same for callback, if function is callbaack, eval call "${@}"
# - "callhook 'custom pre' 'custom post' func arg1 arg2 ..."
#   - both
# - "call{insert,replace} pos# 'custom command args' func"
#   - default position to 0
#   - insert a custom command at the specified location
#     - newfunc=( $(declare -f func | getfuncbody) )
#     - newfunc[0]="function function_${RANDOM}()"
#     - for e in $(seq ${#} -1 ${i}) ; do newfunc[${e}]="${newfunc[$((${e}-1))]}" ; done
#     - newfunc[${i}]="custom command args"
#   - replace is just newfunc[${i}]="custom command args"
# - "call{prepend,append} 'custom command' func"
#   - prepend: insert at line 0 of func body
#   - append: just tack onto the end of the func body
# - "callreinplace '^bash|(-|_)regex(\.pattern|)$' 'custom replacement' func
#   - if [[ $line =~ $pattern ]] ...
# - "callbuild func 'command 1' 'command 2' 'command3 | command4'
#   - append to func body
# - passing a whole lot of function bodies around
# - could lead to self-modifying shell script, o h t h e h o r r o r
#
# useful funcs
# - variables : "varexists varname"    "vartype varname"
# - array     : "arrayexists arrayvar" "isarray arrayvary" "createarray arrayvar" "savearray arrayvar" "uniqarray arrayvar"
# - hash      : "hashexists hashvar"   "ishash hashvar"    "createhash hashvar"   "getkeys hashvar"    "haskey hashvar key" "savehash hashvar"
#
# cool subleq+eforth thing: https://howerj.github.io/subleq.htm
# - subleq could be implemented with ternary operators, (statement==value)?(true):(false)
# - hmm
# - "nested" oisc machine threads w/state...
# - not super complicated
#

function showstack() {
  echo stack:
  n=2
  for i in $(seq $((${#FUNCNAME[@]}-1)) -1 0) ; do
    for d in $(seq 0 $((${n}-1))) ; do
      echo -n " "
    done
    echo ${FUNCNAME[${i}]}
    ((n=n+2))
  done
}

function showcallerinfo() {
  fn=${FUNCNAME[1]}
  IFS=_ read v t e <<< $fn
  e=${fn#${v}_${t}_}
  if [ -z "${t}" ] ; then
    echo $fn : not in verb target extra format
  else
    echo $fn : verb: $v , target: $t , extra: $e
  fi
  showstack
  echo
}

function k_l_m_n() {
  showcallerinfo
}

function h_i_j() {
  k_l_m_n
  k_l_m_n
}

function d_e_f() {
  h_i_j
}

function a_b_c() {
  showcallerinfo
  d_e_f
}

function runner() {
  showcallerinfo
  a_b_c
  k_l_m_n
}

showcallerinfo
runner
