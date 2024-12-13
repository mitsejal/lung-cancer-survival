const margin = { top: 40, right: 40, bottom: 60, left: 80 };
const width = 800 - margin.left - margin.right;
const height = 500 - margin.top - margin.bottom;

const svg = d3.select("#plot")
  .append("svg")
  .attr("width", width + margin.left + margin.right)
  .attr("height", height + margin.top + margin.bottom)
  .append("g")
  .attr("transform", `translate(${margin.left},${margin.top})`);

const xScale = d3.scaleLinear().range([0, width]);
const yScale = d3.scaleLinear().domain([0, 1]).range([height, 0]);

const xAxis = svg.append("g").attr("transform", `translate(0,${height})`);
const yAxis = svg.append("g");

svg.append("text")
  .attr("x", width / 2)
  .attr("y", height + 40)
  .text("Time (days)");

svg.append("text")
  .attr("x", -height / 2)
  .attr("y", -50)
  .attr("transform", "rotate(-90)")
  .text("Survival Probability");

const tooltip = d3.select("#tooltip");

function updateChart(data, variable) {
  const filteredData = data.filter(d => d.variable === variable);
  const groups = d3.group(filteredData, d => d[variable]);

  const maxTime = d3.max(filteredData, d => d.time);
  xScale.domain([0, maxTime]);

  xAxis.call(d3.axisBottom(xScale));
  yAxis.call(d3.axisLeft(yScale));

  const line = d3.line()
    .x(d => xScale(d.time))
    .y(d => yScale(d.survival))
    .curve(d3.curveStepAfter);

  const lines = svg.selectAll(".line").data(Array.from(groups), d => d[0]);

  lines.enter()
    .append("path")
    .attr("class", "line")
    .attr("fill", "none")
    .attr("stroke", (d, i) => d3.schemeCategory10[i % 10])
    .merge(lines)
    .attr("d", d => line(d[1]));

  lines.exit().remove();
}

// Add dropdown functionality
let loadedData; // Declare a variable to store the loaded data

d3.json("data/survival_data.json")
  .then(data => {
    loadedData = data;
    updateChart(loadedData, "sex");

    // Add event listener for the dropdown
    d3.select("#variable-dropdown").on("change", function () {
      const selectedVariable = this.value; // Get the selected variable
      updateChart(loadedData, selectedVariable); // Update the chart with the selected variable
    });
  })
  .catch(error => console.error("Error loading data:", error));
