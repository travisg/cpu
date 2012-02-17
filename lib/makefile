
TARGET := libcpu
BUILDDIR := build-$(TARGET)

# compiler flags, default libs to link against
COMPILEFLAGS := -g -O0 -Wall
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
	Dis.o

OBJS := $(addprefix $(BUILDDIR)/,$(OBJS))

DEPS := $(OBJS:.o=.d)

$(BUILDDIR)/$(TARGET).a: $(OBJS)
	$(AR) rc $@ $(OBJS)

clean:
	rm -f $(OBJS) $(DEPS) $(TARGET) $(BUILDDIR)/*.c $(BUILDDIR)/*.cpp

spotless:
	rm -rf build-*

# makes sure the target dir exists
MKDIR = if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi

$(BUILDDIR)/%.tab.cpp: %.ypp
	@$(MKDIR)
	@echo generating $<
	@bison -o $@ --debug $<

$(BUILDDIR)/lex.yy.c: scanner.l
	@$(MKDIR)
	@echo generating $@
	@flex -o $@ $<

$(BUILDDIR)/%.o: $(BUILDDIR)/%.tab.cpp $(BUILDDIR)/lex.yy.c
	@$(MKDIR)
	@echo compiling $<
	@$(CC) $(CPPFLAGS) -I. -I$(BUILDDIR) -c $< -MD -MT $@ -MF $(@:%o=%d) -o $@

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
