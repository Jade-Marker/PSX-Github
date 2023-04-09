##Intensley mangled makefile, adapted from the ones provided by nolibgs

TARGET = Main

SRCDIRS = src
DATADIRS = data

SRCS := $(foreach dir,$(SRCDIRS), $(addprefix $(SRCDIRS)/, $(notdir $(wildcard $(dir)/*.c)))) 
SRCS += $(foreach dir,$(DATADIRS), $(addprefix $(DATADIRS)/, $(notdir $(wildcard $(dir)/*.tim))))

BUILDDIR = ./build
BINDIR = ./build/

#Obviously needs to be set based on your system
NOLIBGSDIR = ./no_libgs_hello_worlds/

# If you change this to exe, you'll have to rename the file ./thirdparty/nugget/ps-exe.ld too.
TYPE = ps-exe

THISDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

SRCS += $(NOLIBGSDIR)thirdparty/nugget/common/crt0/crt0.s
SRCS += $(NOLIBGSDIR)thirdparty/nugget/common/syscalls/printf.s 

CPPFLAGS += -I$(NOLIBGSDIR)thirdparty/nugget/psyq/include -I$(NOLIBGSDIR)psyq-4_7-converted/include -I$(NOLIBGSDIR)psyq-4.7-converted-full/include -I$(NOLIBGSDIR)psyq/include 
LDFLAGS += -L$(NOLIBGSDIR)thirdparty/nugget/psyq/lib -L$(NOLIBGSDIR)psyq-4_7-converted/lib -L$(NOLIBGSDIR)psyq-4.7-converted-full/lib -L$(NOLIBGSDIR)psyq/lib
# add support for NDR008's VScode setup
CPPFLAGS += -I$(NOLIBGSDIR)../third_party/psyq/include
LDFLAGS += -L$(NOLIBGSDIR)../third_party/psyq/lib
LDFLAGS += -Wl,--start-group
LDFLAGS += -lapi
LDFLAGS += -lc
LDFLAGS += -lc2
LDFLAGS += -lcard
LDFLAGS += -lcomb
LDFLAGS += -lds
LDFLAGS += -letc
LDFLAGS += -lgpu
LDFLAGS += -lgs
LDFLAGS += -lgte
LDFLAGS += -lgun
LDFLAGS += -lhmd
LDFLAGS += -lmath
LDFLAGS += -lmcrd
LDFLAGS += -lmcx
LDFLAGS += -lpad
LDFLAGS += -lpress
LDFLAGS += -lsio
LDFLAGS += -lsnd
LDFLAGS += -lspu
LDFLAGS += -ltap
LDFLAGS += -lcd
LDFLAGS += -Wl,--end-group


BUILD ?= Release

HAS_LINUX_MIPS_GCC = $(shell which mipsel-linux-gnu-gcc > /dev/null 2> /dev/null && echo true || echo false)

ifeq ($(HAS_LINUX_MIPS_GCC),true)
PREFIX ?= mipsel-linux-gnu
FORMAT ?= elf32-tradlittlemips
else
PREFIX ?= mipsel-none-elf
FORMAT ?= elf32-littlemips
endif

ROOTDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

CC  = $(PREFIX)-gcc
CXX = $(PREFIX)-g++

TYPE ?= cpe
LDSCRIPT ?= $(ROOTDIR)/$(TYPE).ld
ifneq ($(strip $(OVERLAYSCRIPT)),)
LDSCRIPT := $(addprefix $(OVERLAYSCRIPT) , -T$(LDSCRIPT))
else
LDSCRIPT := $(addprefix $(ROOTDIR)/default.ld , -T$(LDSCRIPT))
endif

USE_FUNCTION_SECTIONS ?= true

ARCHFLAGS = -march=mips1 -mabi=32 -EL -fno-pic -mno-shared -mno-abicalls -mfp32
ARCHFLAGS += -fno-stack-protector -nostdlib -ffreestanding
ifeq ($(USE_FUNCTION_SECTIONS),true)
CPPFLAGS += -ffunction-sections
endif
CPPFLAGS += -mno-gpopt -fomit-frame-pointer
CPPFLAGS += -fno-builtin -fno-strict-aliasing -Wno-attributes
CPPFLAGS += $(ARCHFLAGS)
CPPFLAGS += -I$(ROOTDIR)

LDFLAGS += -Wl,-Map=$(BINDIR)$(TARGET).map -nostdlib -T$(LDSCRIPT) -static -Wl,--gc-sections
LDFLAGS += $(ARCHFLAGS) -Wl,--oformat=$(FORMAT)

CPPFLAGS_Release += -Os
LDFLAGS_Release += -Os

CPPFLAGS_Debug += -Og
CPPFLAGS_Coverage += -Og

LDFLAGS += -g
CPPFLAGS += -g

CPPFLAGS += $(CPPFLAGS_$(BUILD))
LDFLAGS += $(LDFLAGS_$(BUILD))

CXXFLAGS += -fno-exceptions -fno-rtti

OBJS += $(addsuffix .o, $(subst data, $(BUILDDIR), $(subst src, $(BUILDDIR), $(basename $(SRCS)))))

all: dep $(BINDIR)$(TARGET).$(TYPE) $(foreach ovl, $(OVERLAYSECTION), $(BINDIR)Overlay$(ovl))

$(BINDIR)Overlay%: $(BINDIR)$(TARGET).elf
	$(PREFIX)-objcopy -j $(@:$(BINDIR)Overlay%=%) -O binary $< $(BINDIR)Overlay$(@:$(BINDIR)Overlay%=%)

$(BINDIR)$(TARGET).$(TYPE): $(BINDIR)$(TARGET).elf
	$(PREFIX)-objcopy $(addprefix -R , $(OVERLAYSECTION)) -O binary $< $@

$(BINDIR)$(TARGET).elf: $(OBJS)
ifneq ($(strip $(BINDIR)),)
#	mkdir -p $(BINDIR)
endif
	$(CC) -g -o $(BINDIR)$(TARGET).elf $(OBJS) $(LDFLAGS)

$(BINDIR)%.o: %.s
	$(CC) $(ARCHFLAGS) -I$(ROOTDIR) -g -c -o $@ $<

%.dep: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -M -MT $(addsuffix .o, $(subst src, $(BUILDDIR), $(basename $@))) -MF $(subst src, $(BUILDDIR), $@) $<

%.dep: %.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -M -MT $(addsuffix .o, $(subst src, $(BUILDDIR), $(basename $@))) -MF $(subst src, $(BUILDDIR), $@) $<

%.dep: %.cc
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -M -MT $(addsuffix .o, $(subst src, $(BUILDDIR), $(basename $@))) -MF $(subst src, $(BUILDDIR), $@) $<

$(BINDIR)%.o : src/%.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

# A bit broken, but that'll do in most cases.
%.dep: %.s
	touch $@

DEPS := $(patsubst %.cpp, %.dep,$(filter %.cpp,$(SRCS)))
DEPS += $(patsubst %.cc,  %.dep,$(filter %.cc,$(SRCS)))
DEPS +=	$(patsubst %.c,   %.dep,$(filter %.c,$(SRCS)))
DEPS += $(patsubst %.s,   %.dep,$(filter %.s,$(SRCS)))

dep: $(DEPS)

clean:
	rm -f $(OBJS) $(BINDIR)Overlay.* $(BINDIR)*.elf $(BINDIR)*.ps-exe $(BINDIR)*.map $(DEPS)

ifneq ($(MAKECMDGOALS), clean)
ifneq ($(MAKECMDGOALS), deepclean)
-include $(DEPS)
endif
endif

.PHONY: clean dep all

define OBJCOPYME
$(PREFIX)-objcopy -I binary --set-section-alignment .data=4 --rename-section .data=.rodata,alloc,load,readonly,data,contents -O $(FORMAT) -B mips $< $@
endef

# convert TIM file to bin
$(BINDIR)%.o: data/%.tim
	$(call OBJCOPYME)

# convert VAG files to bin
%.o: %.vag
	$(call OBJCOPYME)
	
# convert HIT to bin
%.o: %.HIT
	$(call OBJCOPYME)
