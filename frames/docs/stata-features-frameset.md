# Stata Features: Saving, Using, and Describing a Set of Frames (Framesets)

Source: https://www.stata.com/features/overview/frameset/
Fetched: 2026-05-19

---

## What Are Frame Sets?

Frame sets represent Stata's solution for managing multiple related datasets simultaneously.
The feature allows users to bundle interconnected datasets into a single file format (**.dtas**),
enabling efficient project-based workflow management.

## Core Capabilities

The frameset functionality includes three primary operations:

1. **Saving**: Users can save a set of frames through the `frames save` command, with automatic
   compression applied.

2. **Using**: The `frames use` command restores all datasets from a frameset file into memory
   at once.

3. **Describing**: The `frames describe` command provides inventory information about frames
   and their contained variables, both in active memory and on disk.

## Key Features

**Automatic Linked Frame Handling**: When saving a frameset, users can specify the `linked`
option to automatically include all frames connected to the primary frame through linking
relationships.

**Compression**: Framesets stored on disk receive automatic compressed formatting, reducing
file size without requiring manual intervention.

**Syntax Consistency**: The command structure mirrors traditional dataset operations. Dataset
and frameset commands similarly handle things like labels, empty datasets, the level of detail
in describing datasets, etc.

## File Format

The **.dtas** extension represents "the plural of **.dta**," creating a standardized format
that Stata reads and writes seamlessly while remaining accessible to external programmers
through documented specifications.

## Practical Example

The documentation demonstrates a census and housing analysis workflow where users:
- Create separate frames for related datasets
- Link frames using `frlink` based on matching variables (state)
- Create variable aliases referencing linked frame data
- Bundle everything into a single **.dtas** file for later retrieval
