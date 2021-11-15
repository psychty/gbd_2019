//  This work is inspired by Jim Vallandingham's amazing work on scrolling. I spent a day or so reading his tutorials on scrollytelling and the fundamentals of the approach.

// I decided to experiment with my own functions and methods to achieve changes over the course of the page.

// Whilst I have not used code from Jim, the approach is very inspired from it. // When scroll position reaches x do y etc.
// https://vallandingham.me/scroller.html

// ! Components
// Bring data in for life expectancy
var request = new XMLHttpRequest();
request.open("GET", "./Outputs/le_wsx.json", false);
request.send(null);

var area_x = "West Sussex";

var le_df = JSON.parse(request.responseText).sort(function (a, b) {
  return +a.Year - +b.Year;
}); // parse the fetched json data into a variable and sort from earliest year to latest (d3 has trouble with the line figure later if it isnt sorted).

// Nest the le_df into sub arrays for each sex
sex_group_le = d3
  .nest()
  .key(function (d) {
    return d.Sex;
  })
  .entries(le_df);

// List of years in the life expectancy dataset
var years_gbd = d3.range(1990, 2020); // I cannot explain why it returns up to 2019 and not 2020, its to do with index starting on 0, it just does ok.

// Grab some values to use in our report
var area_male_le_1990 = le_df.filter(function (d) {
  return d.Name === area_x && d.Sex === "Male" && d.Year === 1990;
});

var area_female_le_1990 = le_df.filter(function (d) {
  return d.Name === area_x && d.Sex === "Female" && d.Year === 1990;
});

var area_person_le_1990 = le_df.filter(function (d) {
  return d.Name === area_x && d.Sex === "Both" && d.Year === 1990;
});

var area_male_le_2019 = le_df.filter(function (d) {
  return d.Name === area_x && d.Sex === "Male" && d.Year === 2019;
});

var area_female_le_2019 = le_df.filter(function (d) {
  return d.Name === area_x && d.Sex === "Female" && d.Year === 2019;
});

var area_person_le_2019 = le_df.filter(function (d) {
  return d.Name === area_x && d.Sex === "Both" && d.Year === 2019;
});

d3.select("#LE_text_1").html(function () {
  return (
    "Life expectancy has increased in the last 20 years, from " +
    d3.format(".1f")(area_person_le_1990[0]["LE"]) +
    " years in 1999 to <b>" +
    d3.format(".1f")(area_person_le_2019[0]["LE"]) +
    " years in 2019 </b>(" +
    d3.format(".1f")(area_female_le_1990[0]["LE"]) +
    " years to " +
    d3.format(".1f")(area_female_le_2019[0]["LE"]) +
    " years among females and from " +
    d3.format(".1f")(area_male_le_1990[0]["LE"]) +
    " years to " +
    d3.format(".1f")(area_male_le_2019[0]["LE"]) +
    " years among males). This shows a gap of almost four years between males and females in " +
    area_x +
    " in the latest estimated life expectancy at birth."
  );
});

d3.select("#HALE_text_1").html(function () {
  return (
    "Healthy life expectancy has also increased since 1999 from " +
    d3.format(".1f")(area_person_le_1990[0]["HALE"]) +
    " years overall (" +
    d3.format(".1f")(area_female_le_1990[0]["HALE"]) +
    " years and " +
    d3.format(".1f")(area_male_le_1990[0]["HALE"]) +
    " years, for females and males respectively) to " +
    d3.format(".1f")(area_person_le_2019[0]["HALE"]) +
    " years in 2019 (" +
    d3.format(".1f")(area_female_le_2019[0]["HALE"]) +
    " years and " +
    d3.format(".1f")(area_male_le_2019[0]["HALE"]) +
    " years, for females and males respectively). The gain in healthy life expectancy has not been as high (in terms of percentage increase or actual years) compared to gains in overall life expectancy, and similar to overall life expectancy, male healthy life expectancy trails behind females although the gap is much smaller at just over one years difference."
  );
});

d3.select("#sub_optimal_health_text_1").html(function () {
  return (
    "Indeed, the modelled estimates suggest that, on average, a female born in 2019 can expect to live " +
    d3.format(".1f")(
      area_female_le_2019[0]["LE"] - area_male_le_2019[0]["LE"]
    ) +
    " years longer overall compared to males. However, they can expect to live around <b>" +
    d3.format(".1f")(area_female_le_2019[0]["Sub_optimal_health"]) +
    " years (or " +
    d3.format(".1%")(
      area_female_le_2019[0]["Sub_optimal_health"] /
        area_female_le_2019[0]["LE"]
    ) +
    " of their lifetime)</b> in sub-optimal health whilst males can expect to spend <b>" +
    d3.format(".1f")(area_male_le_2019[0]["Sub_optimal_health"]) +
    " years (or " +
    d3.format(".1%")(
      area_male_le_2019[0]["Sub_optimal_health"] / area_male_le_2019[0]["LE"]
    ) +
    " of thier lifetime)</b> with the burden of ill health."
  );
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

var sex_colour = d3
  .scaleOrdinal()
  .domain(["Both", "Female", "Male"])
  .range(["#172243", "#00C3FF", "#fd6400"]);

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
    .attr("text-anchor", "left")
    .attr("class", "life_expectancy_figure chart_title_text")
    .attr("y", 50)
    .attr("x", svg_width * 0.05)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .text("Life expectancy and health-adjusted life expectancy at birth;");

  svg_story
    .append("text")
    .attr("text-anchor", "left")
    .attr("class", "life_expectancy_figure chart_title_text")
    .attr("y", 65)
    .attr("x", svg_width * 0.05)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .text(area_x + "; 1990-2019");

  svg_story
    .append("text")
    .attr("text-anchor", "left")
    .attr("class", "life_expectancy_figure chart_title_text")
    .attr("y", svg_height * 0.55)
    .attr("x", svg_width * 0.1)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .text("2019");

  svg_story
    .append("text")
    .attr("text-anchor", "left")
    .attr("class", "life_expectancy_figure chart_text")
    .attr("y", svg_height * 0.6)
    .attr("x", svg_width * 0.1)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .style("font-weight", "bold")
    .text("Life expectancy at birth");

  svg_story
    .append("text")
    .attr("text-anchor", "left")
    .attr("class", "life_expectancy_figure chart_text")
    .attr("y", svg_height * 0.6 + 15)
    .attr("x", svg_width * 0.1)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .text(
      "Females: " + d3.format(".1f")(area_female_le_2019[0]["LE"]) + " years"
    );

  svg_story
    .append("text")
    .attr("text-anchor", "left")
    .attr("class", "life_expectancy_figure chart_text")
    .attr("y", svg_height * 0.6 + 30)
    .attr("x", svg_width * 0.1)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .text("Males: " + d3.format(".1f")(area_male_le_2019[0]["LE"]) + " years");

  svg_story
    .append("text")
    .attr("text-anchor", "left")
    .attr("class", "life_expectancy_figure chart_text")
    .attr("y", svg_height * 0.6 + 45)
    .attr("x", svg_width * 0.1)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .text(
      "Persons: " + d3.format(".1f")(area_person_le_2019[0]["LE"]) + " years"
    );

  svg_story
    .append("text")
    .attr("text-anchor", "left")
    .attr("class", "life_expectancy_figure chart_text")
    .attr("y", svg_height * 0.6 + 70)
    .attr("x", svg_width * 0.1)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .style("font-weight", "bold")
    .text("Healthy life expectancy at birth");

  svg_story
    .append("text")
    .attr("text-anchor", "left")
    .attr("class", "life_expectancy_figure chart_text")
    .attr("y", svg_height * 0.6 + 85)
    .attr("x", svg_width * 0.1)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .text(
      "Females: " + d3.format(".1f")(area_female_le_2019[0]["HALE"]) + " years"
    );

  svg_story
    .append("text")
    .attr("text-anchor", "left")
    .attr("class", "life_expectancy_figure chart_text")
    .attr("y", svg_height * 0.6 + 100)
    .attr("x", svg_width * 0.1)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .text(
      "Males: " + d3.format(".1f")(area_male_le_2019[0]["HALE"]) + " years"
    );

  svg_story
    .append("text")
    .attr("text-anchor", "left")
    .attr("class", "life_expectancy_figure chart_text")
    .attr("y", svg_height * 0.6 + 115)
    .attr("x", svg_width * 0.1)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .text(
      "Persons: " + d3.format(".1f")(area_person_le_2019[0]["HALE"]) + " years"
    );

  var x_years_gbd = d3
    .scaleLinear()
    .domain(
      d3.extent(le_df, function (d) {
        return d.Year;
      })
    )
    .range([50, svg_width - 50]);

  var y_le = d3
    .scaleLinear()
    .domain([0, 90]) // Add the ceiling
    .range([svg_height - 50, 100]);

  svg_story
    .append("g")
    .attr("class", "life_expectancy_figure axis_text")
    .attr("transform", "translate(50, 0)")
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .call(d3.axisLeft(y_le).ticks(20));

  // append the axis to the svg_story and also rotate just the text labels
  svg_story
    .append("g")
    .attr("class", "life_expectancy_figure axis_text")
    .attr("transform", "translate(0," + (svg_height - 50) + ")")
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

  // Legend

  // Add one dot in the legend for each name.
  svg_story
    .selectAll("dots")
    .data(sex)
    .enter()
    .append("circle")
    .attr("class", "life_expectancy_figure axis_text")
    .attr("cx", svg_width * 0.6)
    .attr("cy", function (d, i) {
      return svg_height * 0.6 + i * 20;
    }) // 100 is where the first dot appears. 20 is the distance between dots
    .attr("r", 4)
    .style("fill", function (d) {
      return sex_colour(sex_transformed(d));
    })
    .style("alignment-baseline", "middle")
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1);

  console.log(sex);

  svg_story
    .selectAll("legend_labels")
    .data(sex)
    .enter()
    .append("text")
    .attr("class", "life_expectancy_figure axis_text")
    .attr("x", svg_width * 0.6 + 10)
    .attr("y", function (d, i) {
      return svg_height * 0.6 + i * 20;
    }) // 100 is where the first dot appears. 20 is the distance between dots
    .style("fill", function (d) {
      return sex_colour(sex_transformed(d));
    })
    .text(function (d) {
      return d.replace("Persons", "Both males and female");
    })
    // .style("font-size", "11px")
    .attr("text-anchor", "left")
    .style("alignment-baseline", "middle")
    .on("click", function (d) {
      currentOpacity = d3.selectAll("." + d).style("opacity"); // is the element currently visible ?
      d3.selectAll("." + d)
        .transition()
        .style("opacity", currentOpacity == 1 ? 0 : 1); // Change the opacity: from 0 to 1 or from 1 to 0
    })
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1);

  svg_story
    .append("text")
    .attr("class", "life_expectancy_figure axis_text")
    .attr("x", svg_width * 0.1)
    .attr("y", 110)
    // .style("font-size", "10px")
    .text("The solid top line shows life expectancy");

  svg_story
    .append("text")
    .attr("class", "life_expectancy_figure axis_text")
    .attr("x", svg_width * 0.4)
    .attr("y", svg_height * 0.4)
    // .style("font-size", "11px")
    .text("The dashed bottom line shows healthy life expectancy");

  // Draw the line
  svg_story
    .selectAll(".line")
    .data(sex_group_le)
    .enter()
    .append("path")
    .attr("class", "life_expectancy_figure")
    .style("fill", "none")
    .attr("stroke", function (d) {
      return sex_colour(d.key);
    })
    .attr("stroke-width", 1)
    .attr("d", function (d) {
      return d3
        .line()
        .x(function (d) {
          return x_years_gbd(d.Year);
        })
        .y(function (d) {
          return y_le(+d.LE);
        })(d.values);
    });

  console.log(sex_group_le);

  svg_story
    .selectAll("myDots")
    .data(sex_group_le)
    .enter()
    .append("g")
    .attr("class", "life_expectancy_figure")
    // .attr("class", function (d) {
    //   return d.key;
    // })
    .style("fill", function (d) {
      return sex_colour(d.key);
    })
    .selectAll("myPoints")
    .data(function (d) {
      return d.values;
    })
    .enter()
    .append("circle")
    .attr("cx", function (d) {
      return x_years_gbd(d.Year);
    })
    .attr("cy", function (d) {
      return y_le(+d.LE);
    })
    .attr("r", 3.5)
    .attr("stroke", "white");

  svg_story
    .selectAll(".line")
    .data(sex_group_le)
    .enter()
    .append("path")
    .attr("class", "life_expectancy_figure")
    .attr("fill", "none")
    .attr("stroke", function (d) {
      return sex_colour(d.key);
    })
    // .attr("stroke-width", 1.5)
    .style("stroke-dasharray", "6,2")
    .attr("d", function (d) {
      return d3
        .line()
        .x(function (d) {
          return x_years_gbd(d.Year);
        })
        .y(function (d) {
          return y_le(+d.HALE);
        })(d.values);
    });
}

function showSection_4() {
  svg_story.selectAll(".life_expectancy_figure").remove();

  //  once we have created section 4 content and section 5 content, we can just use the class selection rather than select by id to remove, this should make it slightly less code
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
