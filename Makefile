PANDOC = pandoc
CROSSREF = pandoc-crossref

META = spec/src/metadata.yaml

PREAMBLE = spec/src/preamble.md
SPEC = \
	spec/src/introduction.md \
	spec/src/data_model.md \
	spec/src/drops.md \
	spec/src/type_conversion.md \
	spec/src/syntax_and_semantics.md \
	spec/src/literals.md \
	spec/src/identifiers.md \
	spec/src/variables_and_paths.md \
	spec/src/operators.md \
	spec/src/filters.md

CSS = style.css
TEMPLATE = spec/template.html

OUT = spec.html
CONCAT = spec.md

PANDOC_FLAGS = \
	--standalone \
	--toc \
	--toc-depth=3 \
	--number-sections \
	--css=$(CSS) \
	--template=$(TEMPLATE) \
	--section-divs \
	--metadata linkReferences=true \
	--mathjax \
	--filter $(CROSSREF)

all: $(OUT)

$(OUT): $(SPEC) $(PREAMBLE) $(TEMPLATE) $(CSS)
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

clean:
	rm -f $(OUT) $(CONCAT)

.PHONY: all clean build concat
