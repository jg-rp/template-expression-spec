PANDOC = pandoc

META = spec/src/metadata.yaml

PREAMBLE = spec/src/preamble.md
SPEC = \
	spec/src/intro.md \
	spec/src/terminology.md \
	spec/src/data_types_and_values.md

CSS = spec/style.css
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
	--metadata linkReferences=true

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
