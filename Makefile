PANDOC = pandoc
CROSSREF = pandoc-crossref

META = src/metadata.yaml

PREAMBLE = src/preamble.md

SPEC_SRC = \
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

PEG_OUT = src/collected_peg_grammar.md
SPEC = $(SPEC_SRC) $(PEG_OUT)

CSS = style.css
TEMPLATE = template.html

BUILD_DIR = site/
OUT = $(BUILD_DIR)/index.html

NOT_FOUND_SRC = 404.html
NOT_FOUND_OUT = $(BUILD_DIR)/404.html

CONCAT = spec.md

# --- Cache-busted CSS ---
CSS_HASH = $(shell shasum $(CSS) | cut -c1-8)
CSS_BUILD = style.$(CSS_HASH).css

# --- Site metadata ---
SITE_URL = https://jg-rp.github.io/template-expression-spec
PUBLISH_BRANCH = gh-pages

PANDOC_FLAGS = \
	--standalone \
	--toc \
	--toc-depth=4 \
	--number-sections \
	--css=$(CSS_BUILD) \
	--template=$(TEMPLATE) \
	--section-divs \
	--metadata linkReferences=true \
	--mathjax \
	--filter $(CROSSREF)

all: $(PEG_OUT) build extras

$(OUT): $(SPEC) $(PREAMBLE) $(TEMPLATE) $(CSS)
	mkdir -p $(BUILD_DIR)

	# Copy hashed CSS
	cp $(CSS) $(BUILD_DIR)/$(CSS_BUILD)

	$(PANDOC) \
	$(META) \
	$(PREAMBLE) \
	$(SPEC) \
	$(PANDOC_FLAGS) \
	-o $(OUT)

$(PEG_OUT): $(SPEC_SRC)
	# Generate collected PEG grammar
	bundle exec ruby collect_peg.rb $(SPEC_SRC) > $@

$(NOT_FOUND_OUT): $(NOT_FOUND_SRC) $(CSS)
	# Copy and rewrite CSS reference to hashed version
	sed 's/style.css/$(CSS_BUILD)/g' $(NOT_FOUND_SRC) > $(NOT_FOUND_OUT)


$(BUILD_DIR)/sitemap.xml:
	echo '<?xml version="1.0" encoding="UTF-8"?>' > $@
	echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' >> $@
	echo '  <url>' >> $@
	echo '    <loc>$(SITE_URL)/</loc>' >> $@
	echo '    <lastmod>'`date +%Y-%m-%d`'</lastmod>' >> $@
	echo '  </url>' >> $@
	echo '</urlset>' >> $@

$(BUILD_DIR)/robots.txt:
	echo 'User-agent: *' > $@
	echo 'Allow: /' >> $@
	echo '' >> $@
	echo 'Sitemap: $(SITE_URL)/sitemap.xml' >> $@

$(BUILD_DIR)/.nojekyll:
	touch $@

extras: \
	$(BUILD_DIR)/404.html \
	$(BUILD_DIR)/sitemap.xml \
	$(BUILD_DIR)/robots.txt \
	$(BUILD_DIR)/.nojekyll

publish: clean all
	# Ensure we're in a git repo
	git rev-parse --is-inside-work-tree >/dev/null 2>&1

	# Create orphan branch in a temp index and push
	cd $(BUILD_DIR) && \
	git init && \
	git checkout -b $(PUBLISH_BRANCH) && \
	touch .nojekyll && \
	git add . && \
	git commit -m "Publish site" && \
	git remote add origin `git -C .. config --get remote.origin.url` && \
	git push --force origin $(PUBLISH_BRANCH)

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

.PHONY: all clean build concat test dev extras publish
