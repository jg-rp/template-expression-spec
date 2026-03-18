PANDOC = pandoc
CROSSREF = pandoc-crossref

META = src/metadata.yaml

PREAMBLE = src/preamble.md
SPEC = \
	src/introduction.md \
	src/data_model.md \
	src/drops.md \
	src/type_conversion.md \
	src/syntax_and_semantics.md \
	src/literals.md \
	src/identifiers.md \
	src/variables_and_paths.md \
	src/operators.md \
	src/filters.md \
	src/arithmetic.md \
	src/primary.md \
	src/appendix.md

CSS = style.css
TEMPLATE = template.html

BUILD_DIR = site/
OUT = $(BUILD_DIR)/spec.html

CONCAT = spec.md

PANDOC_FLAGS = \
	--standalone \
	--toc \
	--toc-depth=4 \
	--number-sections \
	--css=$(CSS) \
	--template=$(TEMPLATE) \
	--section-divs \
	--metadata linkReferences=true \
	--mathjax \
	--filter $(CROSSREF)

all: $(OUT)

$(OUT): $(SPEC) $(PREAMBLE) $(TEMPLATE) $(CSS)
	mkdir -p $(BUILD_DIR)
	cp $(CSS) $(BUILD_DIR)
	$(PANDOC) \
	$(META) \
	$(PREAMBLE) \
	$(SPEC) \
	$(PANDOC_FLAGS) \
	-o $(OUT)

$(CONCAT): $(SPEC) $(PREAMBLE) $(TEMPLATE) $(CSS)
	$(PANDOC) \
	$(META) \
	$(PREAMBLE) \
	$(SPEC) \
	-t commonmark_x \
	-o $(CONCAT)

build: $(OUT)
concat: $(CONCAT)

test:
	bundle exec rake test

dev:
	bundle exec ruby dev.rb

clean:
	rm -rf $(BUILD_DIR) $(CONCAT)

.PHONY: all clean build concat test dev
