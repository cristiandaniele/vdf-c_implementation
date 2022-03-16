### regole di compilazione ###
### nota: non modificare questo file ma le variabili in Makefile.config ###

CONFIG_FILE = Makefile.config
ADV_CONFIG_FILE = Makefile.config.adv

-include $(CONFIG_FILE)
-include $(ADV_CONFIG_FILE)

UNAME := $(shell uname -s)
IS_MAC = $(filter Darwin,$(UNAME))
IS_LNX = $(filter Linux,$(UNAME))
IS_WIN = $(filter Windows_NT,$(OS))

ifeq ($(strip $(IS_MAC)$(IS_WIN)$(IS_LNX)),)
	$(error Unrecognized platform!)
endif

#LIBS := $(if $(and $(filter yes,$(USE_MPIR)),$(filter yes,$(USE_CUSTOM_LIBS))),$(subst gmp,mpir,$(LIBS)),$(LIBS))
CUSTOM_LIBS_DIR := $(if $(and $(filter yes,$(USE_MPIR)),$(CUSTOM_MPIR_BASED_LIBS_DIR),$(filter yes,$(USE_CUSTOM_LIBS))),$(CUSTOM_MPIR_BASED_LIBS_DIR),$(CUSTOM_LIBS_DIR))
USE_RDTSCP := $(if $(IS_LNX)$(IS_WIN), $(shell grep -q rdtscp /proc/cpuinfo && echo yes )) $(if $(IS_MAC), $(shell sysctl -n machdep.cpu.extfeatures | grep -q -i rdtscp && echo yes ))

COMPILER = $(if $(filter yes,$(USE_CLANG)), clang, gcc)
CC = $(COMPILER)
LD = $(COMPILER)
DEPS_GEN = $(COMPILER) -MM $(CFLAGS)
DEPS_FILE = Makefile.deps
RM = rm -f
PLOTTER = gnuplot -c
OTHER_FILES_TO_CLEAN = gmon.out *.perf

SRCS = $(wildcard lib-*.c)
OBJS = $(SRCS:.c=.o)
POBJS = $(addsuffix .o, $(PROGS))
PLOTS = $(wildcard plots/*.plt)
PLOTS_SVG = $(PLOTS:.plt=.svg)

COMMA := ,
CFLAGS += -std=gnu11 -Wall 
CFLAGS += $(if $(filter yes,$(USE_CUSTOM_LIBS)),-I$(CUSTOM_LIBS_DIR)/include/,)
LDFLAGS += $(if $(filter yes,$(USE_CUSTOM_LIBS)),-L$(CUSTOM_LIBS_DIR)/lib/ -Wl$(COMMA)-rpath -Wl$(COMMA)$(CUSTOM_LIBS_DIR)/lib/ -L$(CUSTOM_LIBS_DIR)/lib64/ -Wl$(COMMA)-rpath -Wl$(COMMA)$(CUSTOM_LIBS_DIR)/lib64/,) $(if $(filter yes,$(USE_STATIC)),-static)
CFLAGS += $(if $(filter yes,$(USE_RDTSCP)),-DUSE_RDTSCP,)
CFLAGS += $(if $(filter yes,$(USE_DEBUG)),-g -DPBC_DEBUG $(if $(filter yes,$(USE_CLANG)),-O2,-Og) $(if $(filter yes,$(USE_GPROF)),-pg) $(if $(filter yes,$(USE_GPERFTOOLS)),-DUSE_GPERFTOOLS),-O2 -DNDEBUG)
CFLAGS += $(strip $(shell for L in $(LIBS); do pkg-config --silence-errors --cflags $$L 2> /dev/null; done ))
LDFLAGS += $(strip $(shell for L in $(LIBS); do pkg-config --silence-errors --libs $$L 2> /dev/null || echo "-l$$L"; done ))
LDFLAGS += $(if $(filter yes,$(USE_DEBUG)),$(if $(filter yes,$(USE_GPROF)),-pg) $(if $(filter yes,$(USE_GPERFTOOLS)),-lprofiler))
LDFLAGS += -L/opt/local/lib/ -L/usr/local/lib/
CFLAGS += -I/opt/local/include/ -I/usr/local/include/
BIN_EXT =

ifneq ($(strip $(IS_WIN)),)
	BIN_EXT = .exe
endif

EPROGS = $(addsuffix $(BIN_EXT), $(PROGS))

all: $(EPROGS)

%$(BIN_EXT): $(OBJS) %.o Makefile
	$(LD) $(OBJS) $(basename $@).o -o $@ $(LDFLAGS)

lib-%.o: lib-%.c Makefile
	$(CC) $(CFLAGS) -c $<

$(DEPS_FILE): *.[Cch]
	for i in *.[Cc]; do $(DEPS_GEN) "$${i}"; done > $@

-include $(DEPS_FILE)

plots: $(PLOTS_SVG)

plots/%.svg: plots/%.plt plots/%.plt.dat
	$(PLOTTER) $< $@

.PHONY: clean depend setup_cores restore_cores upload-releases print-%

setup_cpus:
	sudo cpupower frequency-set --governor performance --min 2.5GHz --max 2.5GHz

restore_cpus:
	sudo cpupower frequency-set --governor powersave --min 0.4GHz --max 3.1GHz

upload-releases:
	scp $(RELEASES) diraimondo@www.dmi.unict.it:crypto/1920/examples-*

clean:
	$(RM) $(EPROGS) $(OBJS) $(POBJS) $(DEPS_FILE) $(PLOTS_SVG) $(OTHER_FILES_TO_CLEAN)

depend:
	$(DEPS_GEN) $(CFLAGS) $(SRCS) > $(DEPS_FILE)

print-%:
	@echo $* = $($*)
