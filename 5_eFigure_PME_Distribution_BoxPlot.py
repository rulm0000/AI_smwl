"""5_eFigure_PME_Distribution_BoxPlot.py

Draws the supplement box-and-whisker plot of perceived message effectiveness
(PME) ratings by warning topic for human participants vs. AI personas.

Called from 5_eFigure_PME_Distribution_BoxPlot.do (via Stata's `python script`),
which prepares the pooled data. It can also be run on its own:

    python 5_eFigure_PME_Distribution_BoxPlot.py <input.csv> <output.png>

The CSV has columns pid, topic (1-8), sample (0 = human, 1 = AI persona), pme.
Box statistics follow the same Tukey rules as Stata's `graph box`: boxes span
the 25th-75th percentile, whiskers extend to the most extreme observations
within 1.5 x IQR of the nearer quartile, and observations beyond are plotted
individually.
"""

import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.patches import Patch

# Topic labels match Table 3 (2_Viewpoints_Tables.do)
TOPIC_LABELS = {
    1: "Control",
    2: "Screen time\nbreak warning",
    3: "Depression\nand anxiety",
    4: "Negative\nbody image",
    5: "Addiction",
    6: "Sleep\ndisruption",
    7: "Mental health harms\nto young people",
    8: "Not been\nproven safe",
}

SAMPLES = {
    0: dict(label="Human participants", offset=-0.2, facecolor="white", edgecolor="black"),
    1: dict(label="AI personas", offset=0.2, facecolor="0.78", edgecolor="0.78"),
}

BOX_WIDTH = 0.3


def main(csv_path, png_path):
    data = pd.read_csv(csv_path)

    plt.rcParams.update({
        "font.family": "sans-serif",
        "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
        "font.size": 9,
    })

    fig, ax = plt.subplots(figsize=(9, 5))

    for sample, style in SAMPLES.items():
        positions = [t + style["offset"] for t in TOPIC_LABELS]
        series = [data.loc[(data["sample"] == sample) & (data["topic"] == t), "pme"].dropna()
                  for t in TOPIC_LABELS]
        ax.boxplot(
            series,
            positions=positions,
            widths=BOX_WIDTH,
            whis=1.5,
            patch_artist=True,
            showcaps=False,
            boxprops=dict(facecolor=style["facecolor"], edgecolor=style["edgecolor"], linewidth=0.8),
            whiskerprops=dict(color="black", linewidth=0.8),
            medianprops=dict(color="black", linewidth=2.5, solid_capstyle="butt"),
            flierprops=dict(marker="o", markersize=3.5, markerfacecolor="none",
                            markeredgecolor="0.45", markeredgewidth=0.7),
            zorder=2,
        )

    # Median bars on top so they stay visible when they coincide with a box edge
    for line in ax.lines:
        if line.get_linewidth() == 2.5:
            line.set_zorder(4)

    ax.set_xticks(list(TOPIC_LABELS))
    ax.set_xticklabels(TOPIC_LABELS.values())
    ax.set_xlim(0.4, len(TOPIC_LABELS) + 0.6)
    ax.set_ylim(0.75, 5.25)
    ax.set_yticks(range(1, 6))
    ax.set_ylabel("Perceived Message Effectiveness")
    ax.tick_params(axis="x", length=0)
    ax.tick_params(axis="y", width=0.8)

    for side in ("top", "right"):
        ax.spines[side].set_visible(False)
    ax.spines["bottom"].set_visible(False)
    ax.spines["left"].set_linewidth(0.8)

    handles = [Patch(facecolor=s["facecolor"], edgecolor=s["edgecolor"], linewidth=0.8, label=s["label"])
               for s in SAMPLES.values()]
    ax.legend(handles=handles, loc="upper center", bbox_to_anchor=(0.5, -0.14),
              ncol=2, frameon=False, handlelength=1.6)

    fig.tight_layout()
    fig.savefig(png_path, dpi=300)
    plt.close(fig)
    print(f"Saved {png_path}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("Usage: python 5_eFigure_PME_Distribution_BoxPlot.py <input.csv> <output.png>")
    main(sys.argv[1], sys.argv[2])
