PREFIX ?= /usr
QMLDIR ?= $(PREFIX)/lib/qt6/qml
DEST = $(DESTDIR)$(QMLDIR)/Twilight/Plugins
# The Twilight modules this needs, see DEPENDS.
DEPENDS = $(shell sed 's/\#.*//' DEPENDS 2>/dev/null)

install: check-deps
	install -d $(DEST)
	cp -r Twilight/Plugins/. $(DEST)

uninstall:
	rm -rf $(DEST)

# Says so when a module that is needed isn't where Qt will look for it. It only
# warns, since the module may be installed later, or by a package.
check-deps:
	@for m in $(DEPENDS); do \
		kind=needs; \
		case $$m in \?*) kind='could use'; m=$${m#?};; esac; \
		found=; \
		for d in $(DESTDIR)$(QMLDIR) $(QMLDIR) $$(echo $$QML_IMPORT_PATH | tr : ' '); do \
			[ -d "$$d/Twilight/$$m" ] && found=1; \
		done; \
		[ -n "$$found" ] || echo "twilight: this $$kind Twilight.$$m, which isn't installed: install its repository too"; \
	done

.PHONY: install uninstall check-deps
