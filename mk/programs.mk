programs_list :=

# Build a program with symbolic name $(1).  The program is defined by
# various variables prefixed by ‘$(1)_’:
#
# - $(1)_DIR: the directory containing the sources of the program, and
#   where the (non-installed) program will be placed.
#
# - $(1)_SOURCES: the source files of the program.
#
# - $(1)_LIBS: the symbolic names of libraries on which this program
#   depends.
#
# - $(1)_LDFLAGS: additional linker flags.
#
# - bindir: the directory where the program will be installed.
define build-program =
  _d := $$($(1)_DIR)
  _srcs := $$(foreach src, $$($(1)_SOURCES), $$(_d)/$$(src))
  $(1)_OBJS := $$(addsuffix .o, $$(basename $$(_srcs)))
  _libs := $$(foreach lib, $$($(1)_LIBS), $$($$(lib)_PATH))
  $(1)_PATH := $$(_d)/$(1)

  $$($(1)_PATH): $$($(1)_OBJS) $$(_libs)
	$(QUIET) $(CXX) -o $$@ $(GLOBAL_LDFLAGS) $$($(1)_OBJS) $$($(1)_LDFLAGS) $$(foreach lib, $$($(1)_LIBS), $$($$(lib)_LDFLAGS_USE))

  $(1)_INSTALL_DIR := $$(bindir)
  $(1)_INSTALL_PATH := $$($(1)_INSTALL_DIR)/$(1)

  $$(eval $$(call create-dir,$$($(1)_INSTALL_DIR)))

  install:: $$($(1)_INSTALL_PATH)

  ifeq ($(BUILD_SHARED_LIBS), 1)

    _libs_final := $$(foreach lib, $$($(1)_LIBS), $$($$(lib)_INSTALL_PATH))

    $$($(1)_INSTALL_PATH): $$($(1)_OBJS) $$(_libs_final) | $$($(1)_INSTALL_DIR)
	$(QUIET) $(CXX) -o $$@ $(GLOBAL_LDFLAGS) $$($(1)_OBJS) $$($(1)_LDFLAGS) $$(foreach lib, $$($(1)_LIBS), $$($$(lib)_LDFLAGS_USE_INSTALLED))

  else

    $$($(1)_INSTALL_PATH): $$($(1)_PATH) | $$($(1)_INSTALL_DIR)
	install -t $$($(1)_INSTALL_DIR) $$<

  endif

  # Propagate CXXFLAGS to the individual object files.
  $$(foreach obj, $$($(1)_OBJS), $$(eval $$(obj)_CXXFLAGS=$$($(1)_CXXFLAGS)))

  include $$(wildcard $$(_d)/*.dep)

  programs_list += $$($(1)_PATH)
  clean_files += $$($(1)_PATH) $$(_d)/*.o $$(_d)/*.dep
  dist_files += $$(_srcs)
endef
