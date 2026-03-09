# Introduction

This document is based on Shopify's [Liquid](https://github.com/Shopify/liquid) project and other implementations derived from Shopify's reference implementation.

Historically, Liquid expressions have varied subtly depending on context - certain tags treated operators or filters differently, and precedence rules were not globally consistent.

This document aims to replace ad hoc behavior with a single, context-independent grammar and a clear evaluation model. All operators, filters, and grouping constructs are valid in any expression context, with a single, well-defined precedence hierarchy.
