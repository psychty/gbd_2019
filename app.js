//  This work is inspired by Jim Vallandingham's amazing work on scrolling. I spent a day or so reading his tutorials on scrollytelling and the fundamentals of the approach.

// I decided to experiment with my own functions and methods to achieve changes over the course of the page.

// Whilst I have not used code from Jim, the approach is very inspired from it. // When scroll position reaches x do y etc.
// https://vallandingham.me/scroller.html

// ! Components
// Bring data in for life expectancy
var request = new XMLHttpRequest();
request.open("GET", "./Outputs/le_wsx.json", false);
request.send(null);

var le_df = JSON.parse(request.responseText); // parse the fetched json data into a variable

sex_group_le = d3
  .nest()
  .key(function (d) {
    return d.Sex;
  })
  .entries(le_df);

// List of years in the dataset
var years_gbd = d3.range(1990, 2020); // I cannot explain why it returns up to 2019 and not 2020, its to do with index starting on 0, it just does ok.

d3.select("#LE_text_1").html(function () {
  return "Life expectancy has increased in the last 20 years, from 79.5 years in 1999 to 82.2 years in 2019 (81.6 years to 84.1 years among females and from 77.1 years to 80.2 years among males). This shows a gap of almost four years between males and females in West Sussex in the latest estimated life expectancy at birth.";
});

d3.select("#HALE_text_1").html(function () {
  return "Healthy life expectancy has also increased since 1999 from 68.1 years overall (68.8 years and 67.2 years for females and males respectively) to 70 years in 2019 (70.6 years and 69.4 years for females and males respectively). The gain in healthy life expectancy has not been as high (in terms of percentage increase or actual years) compared to gains in overall life expectancy, and similar to overall life expectancy, male healthy life expectancy trails behind females although the gap is much smaller at just over one years difference.";
});

var svg_width =
  document.getElementById("graphic").offsetWidth -
  document.getElementById("sections").offsetWidth -
  80;

var vh = window.innerHeight * 0.01;

svg_height = 70 * vh;

// if (svg_width < 575) {
var svg_story = d3
  .select("#vis")
  .append("svg")
  .attr("id", "vis_placeholder")
  .attr("height", svg_height)
  .attr("width", svg_width)
  .append("g");
// }

var sex = ["Males", "Females", "Persons"];
var sex_transformed = d3
  .scaleOrdinal()
  .domain(sex)
  .range(["Male", "Female", "Both"]);

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_deaths_sex_filter_button")
  .selectAll("myOptions")
  .data(sex)
  .enter()
  .append("option")
  .text(function (d) {
    return d;
  }) // text to appear in the menu - this does not have to be as it is in the data (you can concatenate other values).
  .attr("value", function (d) {
    return d;
  });

var selectedsexOption = sex_transformed(
  d3.select("#select_deaths_sex_filter_button").property("value")
);

// ! Scrolly

var vis_position = $("#vis")[0].getBoundingClientRect().top; // Where is the data vis vertical position from the top of the viewport (not top of document, as some people may reload part way down)

// Determine the scroll position of the start of each section, minus the vis_position. We'll be setting the application so that the trigger for a new part is when the section is in line with the top of the svg rather than the top of the viewport.
var chosen_position_1 = $("#scroll-one").offset().top - vis_position;
var chosen_position_2 = $("#scroll-two").offset().top - vis_position;
var chosen_position_3 = $("#scroll-three").offset().top - vis_position;
var chosen_position_4 = $("#scroll-four").offset().top - vis_position;
var chosen_position_5 = $("#scroll-five").offset().top - vis_position;
var chosen_position_6 = $("#scroll-six").offset().top - vis_position;

var section_array = [
  chosen_position_1,
  chosen_position_2,
  chosen_position_3,
  chosen_position_4,
  chosen_position_5,
  chosen_position_6,
];

var section_labels = [
  "First section",
  "Second section",
  "Third section",
  "Fourth section",
  "Fifth section",
  "Sixth section",
];

var trigger_functions = [
  showSection_1(),
  showSection_2(),
  showSection_3(),
  showSection_4(),
  showSection_5(),
  showSection_6(),
];

// This sets up some identifiers for each section. We'll use this as a sort of lookup. It says if the input is chosen_position_1 then output 'First section' and so on
var section_index = d3
  .scaleOrdinal()
  .domain(section_array)
  .range(section_labels);

// Get the current position of the top of the viewport in relation to the document
var current_scroll_position = $(this).scrollTop();
var active_section = null; // initialise a variable called active_section

if (current_scroll_position < chosen_position_2) {
  active_section = section_index(chosen_position_1);
} else if (
  current_scroll_position >= chosen_position_2 &&
  current_scroll_position < chosen_position_3
) {
  active_section = section_index(chosen_position_2);
} else if (
  current_scroll_position >= chosen_position_3 &&
  current_scroll_position < chosen_position_4
) {
  active_section = section_index(chosen_position_3);
} else if (
  current_scroll_position >= chosen_position_4 &&
  current_scroll_position < chosen_position_5
) {
  active_section = section_index(chosen_position_4);
} else if (
  current_scroll_position >= chosen_position_5 &&
  current_scroll_position < chosen_position_6
) {
  active_section = section_index(chosen_position_5);
} else {
  active_section = "You have reached the end";
}

console.log(active_section);

switch (active_section) {
  case "First section":
    showSection_1();
    break;
  case "Second section":
    showSection_2();
    break;
  case "Third section":
    showSection_3();
    break;
  case "Fourth section":
    showSection_4();
    break;
  case "Fifth section":
    showSection_5();
    break;
  case "Sixth section":
    showSection_6();
}

//  We want to be able to tell if the active_section changes. To do this we need to store the current section and then compare it to the new one. Store the active_section as 'old_active'
var old_active = active_section;

// This function is storing the scroll position as well as storing the existing active_section as 'old_active', updating the active_section, and then when the old_active and active_section values are different (indicative that the user has moved between sections) a new event occurs
function check_scroll_pos() {
  current_scroll_position = $(this).scrollTop();

  if (current_scroll_position < chosen_position_2) {
    old_active = active_section;
    active_section = section_index(chosen_position_1);
  } else if (
    current_scroll_position >= chosen_position_2 &&
    current_scroll_position < chosen_position_3
  ) {
    old_active = active_section;
    active_section = section_index(chosen_position_2);
  } else if (
    current_scroll_position >= chosen_position_3 &&
    current_scroll_position < chosen_position_4
  ) {
    old_active = active_section;
    active_section = section_index(chosen_position_3);
  } else if (
    current_scroll_position >= chosen_position_4 &&
    current_scroll_position < chosen_position_5
  ) {
    old_active = active_section;
    active_section = section_index(chosen_position_4);
  } else if (
    current_scroll_position >= chosen_position_5 &&
    current_scroll_position < chosen_position_6
  ) {
    old_active = active_section;
    active_section = section_index(chosen_position_5);
  } else {
    old_active = active_section;
    active_section = "You have reached the end";
  }

  // We only want this to trigger if a user moves into a DIFFERENT section, and not every time the scroll position changes (e.g. a small scroll within a single section).
  // In particular we can tell where a user came from as well (whether they are scrolling down through or back up the sections).
  if (old_active !== active_section) {
    console.log(
      "You must have changed section from",
      old_active,
      "to",
      active_section,
      ". The relevant viz should occur now"
    );

    // We can now trigger the relevant function based on whatever the active_section is.
    switch (active_section) {
      case "First section":
        showSection_1();
        break;
      case "Second section":
        showSection_2();
        break;
      case "Third section":
        showSection_3();
        break;
      case "Fourth section":
        showSection_4();
        break;
      case "Fifth section":
        showSection_5();
        break;
      case "Sixth section":
        showSection_6();
    }

    console.log(active_section);
  }
}

// This currently fires the check_scroll_pos every time the scroll position changes.
window.onscroll = function () {
  check_scroll_pos();
};

// ! Section 1 Key summary
function showSection_1() {
  svg_story.selectAll(".life_expectancy_figure").remove();

  svg_story
    .selectAll("#section_vis_placeholder_text")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

  svg_story
    .selectAll("#section_placeholder_image")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

  svg_story
    .append("image")
    .attr("id", "section_placeholder_image")
    .attr("xlink:href", "Outputs/key_findings.svg")
    .attr("width", svg_width)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1);
}

// ! Section 2 Whats a DALY
function showSection_2() {
  svg_story.selectAll(".life_expectancy_figure").remove();

  svg_story
    .selectAll("#section_vis_placeholder_text")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

  svg_story
    .selectAll("#section_placeholder_image")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

  svg_story
    .append("image")
    .attr("id", "section_placeholder_image")
    .attr("xlink:href", "Outputs/daly.svg")
    .attr("width", svg_width)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1);
}

// ! Section 3 Life Expectancy
function showSection_3() {
  svg_story
    .selectAll("#section_vis_placeholder_text")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

  svg_story
    .selectAll("#section_placeholder_image")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

  svg_story
    .append("text")
    .attr("text-anchor", "middle")
    .attr("id", "section_vis_placeholder_text")
    .attr("class", "life_expectancy_figure")
    .attr("y", 200)
    .attr("x", svg_width * 0.5)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .style("font-weight", "bold")
    .text("Life expectancy");

  var x_years_gbd = d3
    .scaleLinear()
    .domain(
      d3.extent(le_df, function (d) {
        return d.Year;
      })
    )
    .range([0, svg_width - 100]);

  var y_le = d3
    .scaleLinear()
    .domain([0, 90]) // Add the ceiling
    .range([svg_height - 50, 50]);

  svg_story
    .append("g")
    .attr("class", "life_expectancy_figure")
    .attr("transform", "translate(50, 0)")
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .call(d3.axisLeft(y_le).ticks(20));

  // append the axis to the svg_story and also rotate just the text labels
  svg_story
    .append("g")
    .attr("class", "life_expectancy_figure")
    .attr("transform", "translate(50," + (svg_height - 50) + ")")
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .call(d3.axisBottom(x_years_gbd).ticks(years_gbd.length, "0f"))
    .selectAll("text")
    .style("text-anchor", "end")
    .attr("dx", "-.8em")
    .attr("dy", ".15em")
    .attr("transform", function (d) {
      return "rotate(-45)";
    });

  console.log(years_gbd.length);
}

function showSection_4() {
  svg_story.selectAll(".life_expectancy_figure").remove();

  svg_story
    .selectAll("#section_vis_placeholder_text")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

  svg_story
    .selectAll("#section_placeholder_image")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

  svg_story
    .append("text")
    .attr("text-anchor", "middle")
    .attr("id", "section_vis_placeholder_text")
    .attr("y", 200)
    .attr("x", svg_width * 0.5)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .style("font-weight", "bold")
    .text("Cause of death");
}

function showSection_5() {
  // svg_story
  //   .selectAll(".life_expectancy_figure")
  //   .transition()
  //   .duration(750)
  //   .style("opacity", 0)
  //   .remove();

  svg_story
    .selectAll("#section_vis_placeholder_text")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

  svg_story
    .selectAll("#section_placeholder_image")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

  svg_story
    .append("text")
    .attr("text-anchor", "middle")
    .attr("id", "section_vis_placeholder_text")
    .attr("y", 200)
    .attr("x", svg_width * 0.5)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .style("font-weight", "bold")
    .text("Change over time");
}

function showSection_6() {
  // svg_story
  // .selectAll(".life_expectancy_figure")
  // .transition()
  // .duration(750)
  // .style("opacity", 0)
  // .remove();

  svg_story
    .selectAll("#section_vis_placeholder_text")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

  svg_story
    .selectAll("#section_placeholder_image")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();
}
