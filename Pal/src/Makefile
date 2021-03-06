export PAL_DIR = $(CURDIR)
export RUNTIME_DIR = $(CURDIR)/../../Runtime

include ../../Makefile.configs
include ../../Makefile.rules
include Makefile.Host

# Customizable PAL Targets
# (specify in Makefile.am in host-specific directories)
# For concurrent builds, all PAL targets must be in host-specific directories
pal_loader =
pal_lib =
pal_lib_deps =
pal_lib_post =
pal_static =
pal_gdb =

include host/$(PAL_HOST)/Makefile.am

HOST_DIR = host/$(PAL_HOST)
LIB_DIR = $(HOST_DIR)/.lib
OBJ_DIR = $(HOST_DIR)/.obj

CFLAGS	+= -I. -I../include -I$(HOST_DIR) -I../lib

ifeq ($(PROFILING),1)
CFLAGS	+= -DPROFILING=1
endif

# Build Targets:
#     (1) Host-specific targets are in "host/{Host Name}".
#     (2) Generic targets are in "host/{Host Name}/.obj".
#     (3) API library targets are in "host/{Host Name}/.lib".

files_to_build = $(pal_lib) $(pal_lib_post) $(pal_static) \
		 $(pal_loader)

defs	= -DIN_PAL -DHOST_TYPE="$(PAL_HOST)" -D$(PAL_HOST_MACRO) -DPAL_DIR=$(PAL_DIR) \
	  -DRUNTIME_DIR=$(RUNTIME_DIR)
CFLAGS += $(defs)
objs	= $(addprefix db_,streams memory threading mutex events process \
	    object main misc exception rtld) slab printf pal_error

graphene_lib = $(LIB_DIR)/graphene-lib.a
host_lib = $(HOST_DIR)/libpal-$(PAL_HOST).a

ifeq ($(findstring x86_64,$(SYS))$(findstring linux,$(SYS)),x86_64linux)
files_to_build += user_start.o user_shared_start.o
endif

ifeq ($(DEBUG),1)
CC += -gdwarf-2 -g3
CFLAGS += -DDEBUG
endif
export DEBUG

# Install Targets (all in RUNTIME_DIR):
#       pal-{Host Name}:       loader for PAL (as an executable)
#       libpal-{Host Name}.so: dynamic-linking library
#       pal_gdb-{Host Name}:   debugger for PAL (as an executable)

ifneq ($(pal_loader),)
	runtime_loader += $(RUNTIME_DIR)/pal-$(PAL_HOST)
endif

ifneq ($(pal_lib),)
	runtime_lib += $(RUNTIME_DIR)/libpal-$(PAL_HOST)$(suffix $(pal_lib))
endif

ifneq ($(pal_gdb),)
	runtime_gdb += $(RUNTIME_DIR)/pal_gdb-$(PAL_HOST)
endif

files_to_install = $(runtime_loader) $(runtime_lib) $(runtime_sec) $(runtime_gdb)


###########################
##  Generic Build Rules  ##
###########################

.PHONY: all
all: $(files_to_build) $(files_to_install)

$(LIB_DIR)/host_endian.h: $(HOST_DIR)/host_endian.h
	@mkdir -p $(LIB_DIR)
	$(call cmd,ln_sf)

.PHONY: host_lib_recurse graphene_lib_recurse

graphene_lib_recurse: $(LIB_DIR)/host_endian.h
	$(MAKE) -C ../lib target=$(abspath $(LIB_DIR))/

$(graphene_lib): graphene_lib_recurse
	@true

host_lib_recurse: $(graphene_lib)
	@[ ! -d host/$(PAL_HOST) ] || $(MAKE) -C host/$(PAL_HOST)

$(host_lib): host_lib_recurse
	@true

$(pal_loader): $(host_lib)

ifneq ($(pal_loader),)
$(runtime_loader): $(pal_loader)
	$(call cmd,ln_sf)
endif

ifneq ($(pal_lib),)
$(pal_lib): $(addprefix $(OBJ_DIR)/,$(addsuffix .o,$(objs))) \
	    $(host_lib) $(graphene_lib) $(pal_lib_deps)
	$(call cmd,ld_so_o)

$(runtime_lib): $(pal_lib)
	$(call cmd,ln_sf)
endif

ifneq ($(pal_gdb),)
$(runtime_gdb): $(pal_gdb)
	$(call cmd,ln_sf)
endif

ifneq ($(pal_lib_post),)
$(pal_lib_post): $(pal_lib)
	@$(MAKE) -C $(HOST_DIR) $@
endif

$(pal_static): $(addprefix $(OBJ_DIR)/,$(addsuffix .o,$(objs))) \
	       $(host_lib) $(graphene_lib)
	$(call cmd,ar_a_o)

user_start.o: ASFLAGS =
user_start.o: user_start.S
	$(call cmd,as_o_S)

user_shared_start.o: ASFLAGS = -DSHARED -fPIC
user_shared_start.o: user_start.S
	$(call cmd,as_o_S)

$(OBJ_DIR)/%.o: %.c
	@mkdir -p $(OBJ_DIR)
	$(call cmd,cc_o_c)

$(OBJ_DIR)/%.i: %.c $(headers)
	@mkdir -p $(OBJ_DIR)
	$(call cmd,cpp_i_c)

$(OBJ_DIR)/%.s: %.c $(headers)
	@mkdir -p $(OBJ_DIR)
	$(call cmd,cc_s_c)

ifeq ($(filter clean,$(MAKECMDGOALS)),)
include $(wildcard *.d)
endif

.PHONY: clean
clean:
	rm -rf $(LIB_DIR) $(OBJ_DIR) $(files_to_build) *.d
	@[ ! -d $(HOST_DIR) ] || $(MAKE) -C $(HOST_DIR) clean

.PHONY: test
test:
	$(MAKE) -C $(HOST_DIR) test

.PHONY: sgx-tokens
sgx-tokens:
	$(MAKE) -C $(HOST_DIR) sgx-tokens
