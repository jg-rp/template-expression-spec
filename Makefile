PANDOC = pandoc

META = spec/src/metadata.yaml

PREAMBLE = spec/src/preamble.md
SPEC = \
	spec/src/introduction.md \
	spec/src/data_types_and_values.md \
	spec/src/literals.md \
	spec/src/variables_and_paths.md \
	spec/src/operators.md \
	spec/src/filters.md

CSS = style.css
TEMPLATE = spec/template.html

OUT = spec.html

PANDOC_FLAGS = \
	--standalone \
	--toc \
	--toc-depth=4 \
	--number-sections \
	--css=$(CSS) \
	--template=$(TEMPLATE) \
	--section-divs \
	--metadata linkReferences=true \
	--mathjax

all: $(OUT)

$(OUT): $(SPEC) $(PREAMBLE) $(TEMPLATE) $(CSS)
	$(PANDOC) \
	$(META) \
	$(PREAMBLE) \
	$(SPEC) \
	$(PANDOC_FLAGS) \
	-o $(OUT)

build: $(OUT)

clean:
	rm -f $(OUT)

.PHONY: all clean build
