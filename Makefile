PREFIX ?= /usr
QMLDIR ?= $(PREFIX)/lib/qt6/qml
DEST = $(DESTDIR)$(QMLDIR)/Twilight/Plugins

install:
	install -d $(DEST)
	cp -r Twilight/Plugins/. $(DEST)

uninstall:
	rm -rf $(DEST)

.PHONY: install uninstall
