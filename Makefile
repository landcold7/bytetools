CXX = g++-9
SHELL = /bin/bash -o pipefail
ALGOROOT = ${ALGO}

CXXFLAGS = -Wall -Wextra -pedantic -std=c++17 -Wshadow -Wformat=2
CXXFLAGS += -Wfloat-equal -Wcast-qual -Wcast-align -fvisibility=hidden # -Wconversion

# By default sets to debug mode.
DEBUG ?= 1
RLOG ?= 1
GDB ?= 0
ifeq ($(GDB), 1)
	CXXFLAGS += -O0 -g
	DBGFLAGS += -fsanitize=address -fsanitize=undefined -fno-sanitize-recover -g -fmax-errors=2
	DBGFLAGS += -DLOCAL
else ifeq ($(DEBUG), 1)
	CXXFLAGS += -O2
	DBGFLAGS += -fsanitize=address -fsanitize=undefined -fno-sanitize-recover -fmax-errors=2
	DBGFLAGS += -DLOCAL
	# DBGFLAGS += -D_GLIBCXX_DEBUG -D_GLIBCXX_DEBUG_PEDANTIC
	# Since this flag will cause a AddressSantizer error on my debug
	# function `trace`, so here I just simply comment out this one.
	# -fstack-protector
else
	CXXFLAGS += -O2
endif

# For local debug purpose
CXXINCS = -I$(ALGOROOT) -I$(ALGOROOT)/third_party/jngen/includes
# CXXLIBS += -lgvc -lcgraph -lcdt

# byte-test config
CNT ?= 4

ELF := $(notdir $(CURDIR))
CMP := $(ELF)_mp
GEN := $(ELF)_ge
INP := $(ELF).ii

all: curdir test

help:
	@echo "Usage:                       "
	@echo "   make       GDB=1          "
	@echo "   make       DEBUG=0 RLOG=0 "
	@echo "   bmk        DEBUG=0 RLOG=0 "
	@echo "   byte-test  CNT=4 LOG=0    "
	@echo "   bsc  			 generate compare file"
	@echo "   bsg  			 generate random tests"
	@echo "   make comp DEBUG=0 LOG=1 CNT=4 do compare"


curdir:
	@echo $(CURDIR)

ifeq ($(DEBUG), 1)
% : %.cc
	@echo "cxx $<"
	@$(CXX) $(CXXFLAGS) $(DBGFLAGS) $< $(LDFLAGS) -o $@ $(CXXLIBS) $(CXXINCS)
else
% : %.cl
	@echo "cxx $<"
	@$(CXX) -x c++ $(CXXFLAGS) $(DBGFLAGS) $< $(LDFLAGS) -o $@ $(CXXLIBS) $(CXXINCS)
endif

%.cl : %.cc
	@echo "byte-post"
	@byte-post $(ELF)
	@pbcopy < $(ELF).cl && pbpaste 2>&1 >/dev/null

%_mp : %.mp
	@echo "cxx $<"
	@$(CXX) -x c++ $(CXXFLAGS) $(DBGFLAGS) $< $(LDFLAGS) -o $@ $(CXXINCS)

%_ge : %.ge
	@echo "cxx $<"
	@$(CXX) -x c++ --std=c++17 -DLOCAL $< $(CXXINCS) -o $@ $(CXXLIBS)

clean:
	@-rm -rf $(ELF) *_mp *_ge

deepclean: clean
	@-rm -rf *.gg *.ga *.gb *_err_* *.gi std_err

samples: clean
	@rm -rf *.in
	@echo byte-sample $(INP)
	@byte-sample $(INP)

# Run with sample input.
test: samples $(ELF)
	@echo byte-run $(ELF)
	@byte-run $(ELF) $(DEBUG) $(RLOG)

comp: deepclean $(ELF) $(GEN) $(CMP)
	@echo byte-test
	@byte-test $(CNT) $(LOG)

# Run with random generated input data.
run: $(GEN) $(ELF)
	@echo byte-test
	@byte-test $(CNT) $(LOG)

gen: $(GEN)
	./$(GEN)

memory: $(ELF)
	@echo byte-memory
	@byte-memory $(ELF)

.PHONY: all clean run test comp run

print-%:
	@echo $* = $($*)
