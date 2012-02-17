
TARGET := emu
BUILDDIR := build-$(TARGET)

# compiler flags, default libs to link against
COMPILEFLAGS := -g -O4 -Wall -I../lib
CFLAGS :=
CPPFLAGS :=
ASMFLAGS :=
LDFLAGS :=
LDLIBS := -lstdc++

UNAME := $(shell uname -s)
ARCH := $(shell uname -m)

# switch any platform specific stuff here
# ifeq ($(findstring CYGWIN,$(UNAME)),CYGWIN)
# ...
# endif
ifeq ($(UNAME),Darwin)
CC := clang
endif

CFLAGS += $(COMPILEFLAGS)
CPPFLAGS += $(COMPILEFLAGS)
ASMFLAGS += $(COMPILEFLAGS)

OBJS := \
	main.o \
	Mem.o \
	Cpu32.o \

OBJS := $(addprefix $(BUILDDIR)/,$(OBJS))

DEPS := $(OBJS:.o=.d)

LIBS := ../lib/build-libcpu/libcpu.a

$(BUILDDIR)/$(TARGET): $(OBJS) $(LIBS)
	$(CC) $(LDFLAGS) $(OBJS) -o $@ $(LIBS) $(LDLIBS)

../lib/build-libcpu/libcpu.a:
	$(MAKE) -C ../lib

clean:
	rm -f $(OBJS) $(DEPS) $(TARGET) $(BUILDDIR)/*.c $(BUILDDIR)/*.cpp
	$(MAKE) -C ../lib clean

spotless:
	rm -rf build-*

# makes sure the target dir exists
MKDIR = if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi

$(BUILDDIR)/%.o: %.c
	@$(MKDIR)
	@echo compiling $<
	@$(CC) $(CFLAGS) -c $< -MD -MT $@ -MF $(@:%o=%d) -o $@

$(BUILDDIR)/%.o: %.cpp
	@$(MKDIR)
	@echo compiling $<
	@$(CC) $(CPPFLAGS) -c $< -MD -MT $@ -MF $(@:%o=%d) -o $@

$(BUILDDIR)/%.o: %.S
	@$(MKDIR)
	@echo compiling $<
	@$(CC) $(ASMFLAGS) -c $< -MD -MT $@ -MF $(@:%o=%d) -o $@

ifeq ($(filter $(MAKECMDGOALS), clean), )
-include $(DEPS)
endif
