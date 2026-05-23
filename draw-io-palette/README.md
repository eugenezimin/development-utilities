# Draw.io Custom Configuration Guide (Desktop Version)

This guide provides step-by-step instructions on how to apply a global configuration to the **Draw.io Desktop Application**. Applying this configuration will set your customized default shape and line styles, overwrite the default color picker with your de-neonized custom palette, and populate the color chooser with optimized preset swatches.

---

## Step-by-Step Installation Instructions

### Step 1: Open the Advanced Configuration Menu
1. Launch the **Draw.io Desktop** application on your computer.
2. Create a new diagram or open an existing file to access the main layout workspace.
3. In the top application menu bar, click on **Extras** and select **Configuration...** from the dropdown menu.

### Step 2: Paste the Configuration JSON
1. A dialog window titled **Configuration** will appear with a text input area.
2. Clear any existing code inside that text box.
3. Copy the entire JSON code block provided in the section below.
4. Paste the copied JSON directly into the Draw.io configuration text area.
5. Click the **Apply** button at the bottom right of the dialog window.

### Step 3: Restart the Application (Critical)
Draw.io Desktop loads global configuration settings, default shape behaviors, and custom palette grids into memory *only during initialization*. 
1. Close the Draw.io Desktop application completely.
2. Re-open Draw.io Desktop. 
3. Select any shape or connector line—your default styles, de-neonized custom schemes, and cohesive preset color matrix will now be fully active.

---

## 🎨 The Custom Configuration JSON

Copy the following block completely into your **Extras > Configuration...** window:

```json
{
  "defaultVertexStyle": {
    "fontFamily": "Charlie Display",
    "fontSize": "11",
    "fillColor": "#EDF2F7",
    "strokeColor": "#1A202C",
    "strokeWidth": "0.75",
    "rounded": "1",
    "fontColor": "#1A202C",
    "absoluteArcSize": "1"
  },
  "defaultEdgeStyle": {
    "fontFamily": "Charlie Display",
    "fontSize": "11",
    "edgeStyle": "orthogonalEdgeStyle",
    "rounded": "1",
    "jettySize": "auto",
    "orthogonalLoop": "1",
    "fillColor": "#EDF2F7",
    "strokeColor": "#1A202C",
    "strokeWidth": "0.5",
    "endSize": "3",
    "startSize": "3",
    "fontColor": "#1A202C"
  },
  "defaultGridEnabled": true,
  "defaultPageVisible": true,
  "defaultAdaptiveColors": "simple",
  "customColorSchemes": [
    [
      {"fill": "#F5E6E8", "stroke": "#A37A81"},
      {"fill": "#F5ECE1", "stroke": "#B89B74"},
      {"fill": "#F5F3E1", "stroke": "#A8A36F"},
      {"fill": "#E6F4EA", "stroke": "#7CA685"},
      {"fill": "#E8F0F5", "stroke": "#7F9CB0"},
      {"fill": "#EDE7F5", "stroke": "#9482A8"},
      {"fill": "#a2798f", "stroke": "#5C3D4E"},
      {"fill": "#8caba8", "stroke": "#486663"},
      {"fill": "#EDF2F7", "stroke": "#1A202C"},
      {"fill": "#EBF8FF", "stroke": "#2B6CB0"},
      {"fill": "#E6FFFA", "stroke": "#234E52"},
      {"fill": "#FFF5F5", "stroke": "#9B2C2C"}
    ]
  ],
  "presetColors": [
    "1A202C", "2D3748", "4A5568", "718096", "A0AEC0", "CBD5E0", "E2E8F0", "EDF2F7",
    "2B6CB0", "3182CE", "4299E1", "63B3ED", "90CDF4", "BEE3F8", "EBF8FF", "1A365D",
    "2C7A7B", "319795", "4FD1C5", "81E6D9", "B2F5EA", "E6FFFA", "9B2C2C", "E53E3E"
  ]
}