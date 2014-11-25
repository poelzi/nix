XSLTPROC = $(xsltproc) --nonet $(xmlflags) \
  --param section.autolabel 1 \
  --param section.label.includes.component.label 1 \
  --param html.stylesheet \'style.css\' \
  --param xref.with.number.and.title 1 \
  --param toc.section.depth 3 \
  --param admon.style \'\' \
  --param callout.graphics.extension \'.gif\' \
  --param contrib.inline.enabled 0 \
  --stringparam generate.toc "book toc"

docbookxsl = http://docbook.sourceforge.net/release/xsl-ns/1.78.1/

MANUAL_SRCS := $(call rwildcard, $(d), *.xml)


# Do XInclude processing / RelaxNG validation
$(d)/manual.xmli: $(d)/manual.xml $(MANUAL_SRCS) $(d)/version.txt
	$(trace-gen) $(xmllint) --nonet --xinclude $< -o $@.tmp
	@mv $@.tmp $@

$(d)/version.txt:
	$(trace-gen) echo -n $(PACKAGE_VERSION) > $@

# Note: RelaxNG validation requires xmllint >= 2.7.4.
$(d)/manual.is-valid: $(d)/manual.xmli
	$(trace-gen) $(XSLTPROC) --novalid --stringparam profile.condition manual \
	  $(docbookxsl)/profiling/profile.xsl $< 2> /dev/null | \
	  $(xmllint) --nonet --noout --relaxng http://www.oasis-open.org/docbook/xml/5.0/rng/docbook.rng -
	@touch $@

clean-files += $(d)/manual.xmli $(d)/version.txt $(d)/manual.is-valid

dist-files += $(d)/manual.xmli $(d)/version.txt $(d)/manual.is-valid


# Generate man pages.
man-pages := $(foreach n, \
  nix-env.1 nix-build.1 nix-shell.1 nix-store.1 nix-instantiate.1 \
  nix-collect-garbage.1 nix-push.1 nix-pull.1 \
  nix-prefetch-url.1 nix-channel.1 nix-generate-patches.1 \
  nix-install-package.1 nix-hash.1 nix-copy-closure.1 \
  nix.conf.5 nix-daemon.8, \
  $(d)/$(n))

$(firstword $(man-pages)): $(d)/manual.xmli $(d)/manual.is-valid
	$(trace-gen) $(XSLTPROC) --novalid --stringparam profile.condition manpage \
	  $(docbookxsl)/profiling/profile.xsl $< 2> /dev/null | \
	  (cd doc/manual && $(XSLTPROC) $(docbookxsl)/manpages/docbook.xsl -)

$(wordlist 2, $(words $(man-pages)), $(man-pages)): $(firstword $(man-pages))

clean-files += $(d)/*.1 $(d)/*.5 $(d)/*.8

dist-files += $(man-pages)


# Generate the HTML manual.
$(d)/manual.html: $(d)/manual.xml $(MANUAL_SRCS) $(d)/manual.is-valid
	$(trace-gen) $(XSLTPROC) --xinclude --stringparam profile.condition manual \
	  $(docbookxsl)/profiling/profile.xsl $< | \
	  $(XSLTPROC) --output $@ $(docbookxsl)/xhtml/docbook.xsl -

$(foreach file, $(d)/manual.html $(d)/style.css, $(eval $(call install-data-in, $(file), $(docdir)/manual)))

$(foreach file, $(wildcard $(d)/figures/*.png), $(eval $(call install-data-in, $(file), $(docdir)/manual/figures)))

$(foreach file, $(wildcard $(d)/images/callouts/*.gif), $(eval $(call install-data-in, $(file), $(docdir)/manual/images/callouts)))

$(eval $(call install-symlink, manual.html, $(docdir)/manual/index.html))

all: $(d)/manual.html

clean-files += $(d)/manual.html

dist-files += $(d)/manual.html


# Generate the PDF manual.
$(d)/manual.pdf: $(d)/manual.xml $(MANUAL_SRCS) $(d)/manual.is-valid
	$(trace-gen) if test "$(dblatex)" != ""; then \
		cd doc/manual && $(XSLTPROC) --xinclude --stringparam profile.condition manual \
		  $(docbookxsl)/profiling/profile.xsl manual.xml | \
		  $(dblatex) -o $(notdir $@) $(dblatex_opts) -; \
	else \
		echo "Please install dblatex and rerun configure."; \
		exit 1; \
	fi

clean-files += $(d)/manual.pdf
