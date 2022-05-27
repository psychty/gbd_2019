//  This work is inspired by Jim Vallandingham's amazing work on scrolling. I spent a day or so reading his tutorials on scrollytelling and the fundamentals of the approach.

// I decided to experiment with my own functions and methods to achieve changes over the course of the page.

// Whilst I have not used code from Jim, the approach is very inspired from it. // When scroll position reaches x do y etc.
// https://vallandingham.me/scroller.html

// ! parameters
var svg_width =
  document.getElementById("graphic").offsetWidth -
  document.getElementById("sections").offsetWidth -
  80;

var vh = window.innerHeight * 0.01;

svg_height = 80 * vh;

if (window.innerHeight < 600) {
  svg_height = 90 * vh;
}

// console.log(window.innerHeight);

var svg_story = d3
  .select("#vis")
  .append("svg")
  .attr("id", "vis_placeholder")
  // .attr("class", "showing")
  .attr("height", svg_height)
  .attr("width", svg_width)
  .append("g");

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

var request = new XMLHttpRequest();
request.open("GET", "./Outputs/wsx_ranks_df.json", false);
request.send(null);

var rank_df = JSON.parse(request.responseText).sort(function (a, b) {
  return +a.Year - +b.Year;
});

rank_df_number = rank_df.filter(function (d) {
  return d.Level === 2 && d.metric === "Number";
});

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
    " of their lifetime)</b> with the burden of ill health."
  );
});

var sex = ["Persons", "Males", "Females"];
var sex_transformed = d3
  .scaleOrdinal()
  .domain(sex)
  .range(["Both", "Male", "Female"]);

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

var chosen_sex_mortality_df = rank_df_number
  .filter(function (d) {
    return d.sex === selectedsexOption;
  })
  .sort(function (a, b) {
    return +a.Deaths_rank - +b.Deaths_rank;
  })
  .filter(function (d, i) {
    return i < 10;
  });

var y_top_ten_mortality = d3
  .scaleLinear()
  .domain([
    0,
    d3.max(chosen_sex_mortality_df, function (d) {
      return +d.Deaths_value;
    }),
  ]) // Add the ceiling
  .range([svg_height - 200, 100])
  .nice();

var x_top_ten = d3
  .scaleBand()
  .domain(
    d3
      .map(chosen_sex_mortality_df, function (d) {
        return d.cause;
      })
      .keys()
  )
  .range([50, svg_width - 50])
  .padding(0.2);

// Specify a colour palette and order for the level 2 causes
var cause_categories = [
  "HIV/AIDS and sexually transmitted infections",
  "Respiratory infections and tuberculosis",
  "Enteric infections",
  "Neglected tropical diseases and malaria",
  "Other infectious diseases",
  "Maternal and neonatal disorders",
  "Nutritional deficiencies",
  "Neoplasms",
  "Cardiovascular diseases",
  "Chronic respiratory diseases",
  "Digestive diseases",
  "Neurological disorders",
  "Mental disorders",
  "Substance use disorders",
  "Diabetes and kidney diseases",
  "Skin and subcutaneous diseases",
  "Sense organ diseases",
  "Musculoskeletal disorders",
  "Other non-communicable diseases",
  "Transport injuries",
  "Unintentional injuries",
  "Self-harm and interpersonal violence",
];

// We can use this for labels
var shortened_causes = d3
  .scaleOrdinal()
  .domain(cause_categories)
  .range([
    "HIV/AIDS & STIs",
    "Respiratory infections & TB",
    "Enteric infections",
    "Neglected tropical diseases & malaria",
    "Other infectious diseases",
    "Maternal and neonatal disorders",
    "Nutritional deficiencies",
    "Neoplasms",
    "Cardiovascular",
    "Chronic respiratory diseases",
    "Digestive diseases",
    "Neurological disorders",
    "Mental disorders",
    "Substance use disorders",
    "Diabetes & kidney diseases",
    "Skin & subcutaneous diseases",
    "Sense organ diseases",
    "Musculoskeletal disorders",
    "Other non-communicable diseases",
    "Transport injuries",
    "Unintentional injuries",
    "Self-harm & violence",
  ]);

var color_cause_group = d3
  .scaleOrdinal()
  .domain(cause_categories)
  .range([
    "#F8DDEB",
    "#F2B9BF",
    "#EE9187",
    "#EA695C",
    "#D84D42",
    "#AD3730",
    "#7A1C1C",
    "#BCD6F7",
    "#97C4F0",
    "#67A8E7",
    "#528CDB",
    "#376ACB",
    "#1845A5",
    "#CFD6F6",
    "#ADB9ED",
    "#8B96DD",
    "#6978D0",
    "#4E4FB8",
    "#3E3294",
    "#B5DCD0",
    "#76B786",
    "#477A49",
  ]);

// overall burden top ten

var request = new XMLHttpRequest();
request.open("GET", "./Outputs/top_ten_cause_two_overall_burden.json", false);
request.send(null);

var burden_top_ten_df = JSON.parse(request.responseText).sort(function (a, b) {
  return +a.Year - +b.Year;
});

burden_top_ten_df = burden_top_ten_df.filter(function (d) {
  return d.sex_name === "Both";
});

// ! Level three bubbles

var measure_categories = [
  "Deaths",
  "YLLs (Years of Life Lost)",
  "YLDs (Years Lived with Disability)",
  "DALYs (Disability-Adjusted Life Years)",
];

var label_key = d3
  .scaleOrdinal()
  .domain(measure_categories)
  .range(["deaths", "YLLs", "YLDs", " DALYs"]);

var xLabel = 190;
var xCircle = 100;
var yCircle = 190;

var request = new XMLHttpRequest();
request.open("GET", "./Outputs/level_three_df_cause.json", false);
request.send(null);

var level_three_cause_df = JSON.parse(request.responseText);

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_bubbles_measure_filter_button")
  .selectAll("myOptions")
  .data(measure_categories)
  .enter()
  .append("option")
  .text(function (d) {
    return d;
  }) // text to appear in the menu - this does not have to be as it is in the data (you can concatenate other values).
  .attr("value", function (d) {
    return d;
  });

var svg_size_key = d3
  .select("#chart_legend")
  .append("svg")
  .attr("width", document.getElementById("sections").offsetWidth)
  .attr("height", 100);

window.onload = () => {
  loadTable_top_burden(burden_top_ten_df);
};

function loadTable_top_burden(burden_top_ten_df) {
  const tableBody = document.getElementById("top_burden_table");
  var dataHTML = "";

  for (let item of burden_top_ten_df) {
    dataHTML += `<tr><td>${item.sex_name}</td><td>${item["Deaths"]}</td><td>${item["YLLs (Years of Life Lost)"]}</td><td>${item["YLDs (Years Lived with Disability)"]}</td><td>${item["DALYs (Disability-Adjusted Life Years)"]}</td></tr>`;
  }

  tableBody.innerHTML = dataHTML;
}

// ! Ch Ch Ch Changes

var request = new XMLHttpRequest();
request.open("GET", "./Outputs/change_over_time_df_wsx.json", false);
request.send(null);

var change_over_time_df = JSON.parse(request.responseText);

// ! Comparison

var request = new XMLHttpRequest();
request.open("GET", "./Outputs/rate_compare_timeseries.json", false);
request.send(null);

var wsx_compare_df = JSON.parse(request.responseText);

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_over_tie_rate_measure_filter_button")
  .selectAll("myOptions")
  .data(measure_categories)
  .enter()
  .append("option")
  .text(function (d) {
    return d;
  }) // text to appear in the menu - this does not have to be as it is in the data (you can concatenate other values).
  .attr("value", function (d) {
    return d;
  });

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_comparison_area_filter_button")
.selectAll("myOptions")
.data(["England", 'South East England'])
.enter()
.append("option")
.text(function (d) {
  return d;
}) // text to appear in the menu - this does not have to be as it is in the data (you can concatenate other values).
.attr("value", function (d) {
  return d;
});

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_comparison_age_filter_button")
  .selectAll("myOptions")
  .data(["All ages", "Age standardised"])
  .enter()
  .append("option")
  .text(function (d) {
    return d;
  }) // text to appear in the menu - this does not have to be as it is in the data (you can concatenate other values).
  .attr("value", function (d) {
    return d;
  });

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_comparison_measure_filter_button")
  .selectAll("myOptions")
  .data(measure_categories)
  .enter()
  .append("option")
  .text(function (d) {
    return d;
  }) // text to appear in the menu - this does not have to be as it is in the data (you can concatenate other values).
  .attr("value", function (d) {
    return d;
  });

  d3.select("#select_comparison_cause_filter_button")
  .selectAll("myOptions")
  .data(['All causes'].concat(cause_categories))
  .enter()
  .append("option")
  .text(function (d) {
    return d;
  }) // text to appear in the menu - this does not have to be as it is in the data (you can concatenate other values).
  .attr("value", function (d) {
    return d;
  });


var selectedAreaComparisonOption = d3
 .select("#select_comparison_area_filter_button")
 .property("value");

var selectedMeasureComparisonOption = d3
 .select("#select_comparison_measure_filter_button")
 .property("value");

var selectedCauseComparisonOption = d3
 .select("#select_comparison_cause_filter_button")
 .property("value");

var selectedAgeComparisonOption = d3
 .select("#select_comparison_age_filter_button")
 .property("value");

chosen_wsx_compare_df = wsx_compare_df.filter(function (d) {
    return d.Measure === selectedMeasureComparisonOption &&
           d.Area === 'West Sussex' &&
           d.Cause === selectedCauseComparisonOption&&
           d.Age === selectedAgeComparisonOption;
  });

chosen_se_compare_df = wsx_compare_df.filter(function (d) {
    return d.Measure === selectedMeasureComparisonOption &&
           d.Area === 'South East England' &&
           d.Cause === selectedCauseComparisonOption &&
           d.Age === selectedAgeComparisonOption;
     });    
 
chosen_england_compare_df = wsx_compare_df.filter(function (d) {
    return d.Measure === selectedMeasureComparisonOption &&
           d.Area === 'England' &&
           d.Cause === selectedCauseComparisonOption &&
           d.Age === selectedAgeComparisonOption;
     });   

all_areas_compare_df = wsx_compare_df.filter(function (d) {
    return d.Measure === selectedMeasureComparisonOption &&
           d.Cause === selectedCauseComparisonOption &&
           d.Age === selectedAgeComparisonOption;
     });   

  var x_comparison_rate = d3
  .scaleLinear()
  .domain([2009, 2019])
  .range([50, svg_width - 50])

  var y_comparison_rate = d3
    .scaleLinear()
    .domain([
      0,
      d3.max(all_areas_compare_df, function (d) {
        return +d.Upper_estimate;
      }),
    ]) // Add the ceiling
    .range([svg_height - 200, 100])
    .nice();

var comparison_colours = d3.scaleOrdinal()
    .domain(['lower', 'similar', 'higher', ''])
    .range([
      '#00a9e0',
      '#f0b323',
      '#bf0d3e',
      '#c9c9c9'
    ])

var comparison_area_colours = d3.scaleOrdinal()
.domain(['West Sussex', 'South East England', 'England'])
.range(['#000000','#30336b','#999999'
])    

var comparison_label = d3.scaleOrdinal()
.domain(['lower', 'similar', 'higher'])
.range(['significantly lower', 'similar', 'significantly higher'])


// ! Scrolly

var vis_position = $("#vis")[0].getBoundingClientRect().top + 30 * vh; // Where is the data vis vertical position from the top of the viewport (not top of document, as some people may reload part way down)

// Determine the scroll position of the start of each section, minus the vis_position. We'll be setting the application so that the trigger for a new part is when the section is in line with the top of the svg rather than the top of the viewport.
var chosen_position_1 = $("#scroll-one").offset().top - vis_position;
var chosen_position_2 = $("#scroll-two").offset().top - vis_position;
var chosen_position_3 = $("#scroll-three").offset().top - vis_position;
var chosen_position_4 = $("#scroll-four").offset().top - vis_position;
var chosen_position_5 = $("#scroll-five").offset().top - vis_position;
var chosen_position_6 = $("#scroll-six").offset().top - vis_position;
var chosen_position_7 = $("#scroll-seven").offset().top - vis_position;
var chosen_position_8 = $("#scroll-eight").offset().top - vis_position;
var end_position = $("#end-section").offset().top - vis_position;

var section_array = [
  chosen_position_1,
  chosen_position_2,
  chosen_position_3,
  chosen_position_4,
  chosen_position_5,
  chosen_position_6,
  chosen_position_7,
  chosen_position_8,
  end_position,
];

var section_labels = [
  "First section",
  "Second section",
  "Third section",
  "Fourth section",
  "Fifth section",
  "Sixth section",
  "Seventh section",
  "Eighth section",
  "End section",
];

var trigger_functions = [
  showSection_1(),
  showSection_2(),
  showSection_3(),
  showSection_4(),
  showSection_5(),
  showSection_6(),
  showSection_7(),
  showSection_8(),
  showSection_end(),
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
} else if (
  current_scroll_position >= chosen_position_6 &&
  current_scroll_position < chosen_position_7
) {
  active_section = section_index(chosen_position_6);
} else if (
  current_scroll_position >= chosen_position_7 &&
  current_scroll_position < chosen_position_8
) {
  active_section = section_index(chosen_position_7);
} else if (
  current_scroll_position >= chosen_position_8 &&
  current_scroll_position < end_position
) {
  active_section = section_index(chosen_position_8);
} else {
  active_section = "You have reached the end";
}

// console.log(active_section);

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
    break;
  case "Seventh section":
    showSection_7();
    break;
  case "Eighth section":
    showSection_8();
    break;
  case "End section":
    showSection_end();
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
  } else if (
    current_scroll_position >= chosen_position_6 &&
    current_scroll_position < chosen_position_7
  ) {
    old_active = active_section;
    active_section = section_index(chosen_position_6);
  } else if (
    current_scroll_position >= chosen_position_7 &&
    current_scroll_position < chosen_position_8
  ) {
    old_active = active_section;
    active_section = section_index(chosen_position_7);
  } else if (
    current_scroll_position >= chosen_position_8 &&
    current_scroll_position < end_position
  ) {
    old_active = active_section;
    active_section = section_index(chosen_position_8);
  } else  {
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
      break;
    case "Seventh section":
      showSection_7();
      break;
    case "Eighth section":
      showSection_8();
      break;
    case "End section":
      showSection_end();
   }
  }
}

// This currently fires the check_scroll_pos every time the scroll position changes.
window.onscroll = function () {
  check_scroll_pos();
};

// ! Section 1 Key summary
function showSection_1() {
  svg_story.selectAll(".life_expectancy_figure").remove();
  svg_story.selectAll(".mortality_1_figure").remove();
  svg_story.selectAll(".level_three_bubbles_figure").remove();
  svg_story.selectAll(".rate_over_time_comparison_figure").remove();
  svg_story.selectAll(".comparison_figure").remove();

  d3.selectAll("#top_ten_burden_table").classed("top_ten_table_on", false);
  d3.selectAll("#top_ten_burden_table").classed("top_ten_table_off", true);
  d3.selectAll("#top_ten_table_title").classed(
    "top_ten_table_title_style",
    false
  );
  d3.selectAll("#top_ten_table_title").classed("top_ten_table_off", true);

svg_story
  .selectAll("#section_vis_placeholder_text")
  .transition()
  .duration(750)
  .style("opacity", 0)
  .remove();

svg_story
  .selectAll("#section_vis_placeholder_text_2")
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
  .attr("height", svg_height)
  .attr("opacity", 0)
  .transition()
  .duration(1000)
  .attr("opacity", 1);
}

// ! Section 2 Whats a DALY
function showSection_2() {
svg_story.selectAll(".life_expectancy_figure").remove();
svg_story.selectAll(".mortality_1_figure").remove();
svg_story.selectAll(".level_three_bubbles_figure").remove();
svg_story.selectAll(".rate_over_time_comparison_figure").remove();
svg_story.selectAll(".comparison_figure").remove();

svg_story
  .selectAll("#section_vis_placeholder_text")
  .transition()
  .duration(750)
  .style("opacity", 0)
  .remove();

svg_story
  .selectAll("#section_vis_placeholder_text_2")
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
  .attr("height", svg_height)
  .attr("opacity", 0)
  .transition()
  .duration(1000)
  .attr("opacity", 1);
}

// ! Section 3 Life Expectancy
function showSection_3() {
  svg_story.selectAll(".mortality_1_figure").remove();
  svg_story.selectAll(".level_three_bubbles_figure").remove();
  svg_story.selectAll(".rate_over_time_comparison_figure").remove();
  svg_story.selectAll(".comparison_figure").remove();

  d3.selectAll("#top_ten_burden_table").classed("top_ten_table_on", false);
  d3.selectAll("#top_ten_burden_table").classed("top_ten_table_off", true);
  d3.selectAll("#top_ten_table_title").classed(
    "top_ten_table_title_style",
    false
  );
  d3.selectAll("#top_ten_table_title").classed("top_ten_table_off", true);

  svg_story
    .selectAll("#section_vis_placeholder_text")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

    svg_story
    .selectAll("#section_vis_placeholder_text_2")
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
    .call(d3.axisLeft(y_le).ticks(20))
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1);

  // append the axis to the svg_story and also rotate just the text labels
  svg_story
    .append("g")
    .attr("class", "life_expectancy_figure axis_text")
    .attr("transform", "translate(0," + (svg_height - 50) + ")")
    .call(d3.axisBottom(x_years_gbd).ticks(years_gbd.length, "0f"))
    .selectAll("text")
    .style("text-anchor", "end")
    .attr("dx", "-.8em")
    .attr("dy", ".15em")
    .attr("transform", function (d) {
      return "rotate(-45)";
    })
    .style("font-size", ".8rem")
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1);

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
    .attr("r", 5)
    .style("fill", function (d) {
      return sex_colour(sex_transformed(d));
    })
    .style("alignment-baseline", "middle")
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1);

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
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .text("The solid top line shows life expectancy");

  svg_story
    .append("text")
    .attr("class", "life_expectancy_figure axis_text")
    .attr("x", svg_width * 0.4)
    .attr("y", svg_height * 0.5)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
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
    })
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1);

  var tooltip_le = d3
    .select("#vis")
    .append("div")
    .style("opacity", 0)
    .attr("class", "tooltips")
    .style("position", "absolute")
    .style("z-index", "10");

  var showTooltip_le = function (d) {
    tooltip_le.transition().duration(200).style("opacity", 1);

    tooltip_le
      .html(
        "<p>In " +
          d.Year +
          " the life expectancy among " +
          d.Sex.replace(
            "Both",
            "overall among both males and female"
          ).toLowerCase() +
          "s was <b>" +
          d3.format(".1f")(d.LE) +
          "</b></> and the health-adjusted life expectancy was <b>" +
          d3.format(".1f")(d.HALE) +
          "</b>. This means living, on average, <b>" +
          d3.format(".1f")(d.Sub_optimal_health) +
          " years in sub-optimal health</b>.</p> "
      )
      .style("opacity", 1);
    // .style("top", d3.select(this).attr("cy") + "10px")
    // .style("left", d3.select(this).attr("cx") + "10px");
  };

  svg_story
    .selectAll("myDots")
    .data(le_df)
    .enter()
    .append("circle")
    .attr("class", "life_expectancy_figure le_dots")
    .style("fill", function (d) {
      return sex_colour(d.Sex);
    })
    .attr("cx", function (d) {
      return x_years_gbd(d.Year);
    })
    .attr("cy", function (d) {
      return y_le(+d.LE);
    })
    .attr("r", 5)
    .attr("stroke", "white")
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1);

  svg_story
    .selectAll(".le_dots")
    .on("mouseover", function () {
      return tooltip_le.style("visibility", "visible");
    })
    .on("mousemove", showTooltip_le)
    .on("mouseout", function () {
      return tooltip_le.style("visibility", "hidden");
    });

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
    })
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1);
}

// ! Mortality
function showSection_4() {
  svg_story.selectAll(".life_expectancy_figure").remove();
  svg_story.selectAll(".mortality_1_figure_title").remove();
  svg_story.selectAll(".rate_over_time_comparison_figure").remove();
  svg_story.selectAll(".comparison_figure").remove();

  d3.selectAll("#vis_placeholder").classed("top_ten_table_off", false);
  d3.selectAll("#top_ten_burden_table").classed("top_ten_table_on", false);
  d3.selectAll("#top_ten_burden_table").classed("top_ten_table_off", true);
  d3.selectAll("#top_ten_table_title").classed(
    "top_ten_table_title_style",
    false
  );
  d3.selectAll("#top_ten_table_title").classed("top_ten_table_off", true);

  var selectedsexOption = sex_transformed(
    d3.select("#select_deaths_sex_filter_button").property("value")
  );

  var chosen_sex_mortality_df = rank_df_number
    .filter(function (d) {
      return d.sex === selectedsexOption;
    })
    .sort(function (a, b) {
      return +a.Deaths_rank - +b.Deaths_rank;
    })
    .filter(function (d, i) {
      return i < 10;
    });

  //  once we have created section 4 content and section 5 content, we can just use the class selection rather than select by id to remove, this should make it slightly less code
  svg_story
    .selectAll("#section_vis_placeholder_text")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

  svg_story
    .selectAll("#section_vis_placeholder_text_2")
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

  var x_top_ten = d3
    .scaleBand()
    .domain(
      d3
        .map(chosen_sex_mortality_df, function (d) {
          return shortened_causes(d.cause);
        })
        .keys()
    )
    .range([50, svg_width - 50])
    .padding(0.2);

  var y_top_ten_mortality = d3
    .scaleLinear()
    .domain([
      0,
      d3.max(chosen_sex_mortality_df, function (d) {
        return +d.Deaths_value;
      }),
    ]) // Add the ceiling
    .range([svg_height - 200, 100])
    .nice();

  svg_story
    .append("g")
    .attr("class", "mortality_1_figure axis_text mortality_1_figure_y_axis ")
    .attr("transform", "translate(50, 0)")
    // .style("font-size", ".8rem")
    .call(d3.axisLeft(y_top_ten_mortality))
    // .style("font-size", ".8rem")
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1);

  // append the axis to the svg_story and also rotate just the text labels
  svg_story
    .append("g")
    .attr("class", "mortality_1_figure mortality_1_figure_x_axis axis_text")
    .attr("transform", "translate(0," + (svg_height - 200) + ")")

    .call(d3.axisBottom(x_top_ten))
    .selectAll("text")
    .style("text-anchor", "end")
    .attr("dx", "-.8em")
    .attr("dy", ".15em")
    .attr("transform", function (d) {
      return "rotate(-45)";
    })
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1);

  update_sex_change_mortality();

  d3.selectAll("#top_ten_burden_table").classed("top_ten_table_on", false);
  d3.selectAll("#top_ten_burden_table").classed("top_ten_table_off", true);
  d3.selectAll("#top_ten_table_title").classed(
    "top_ten_table_title_style",
    false
  );
  d3.selectAll("#top_ten_table_title").classed("top_ten_table_off", true);
}

d3.select("#select_deaths_sex_filter_button").on("change", function (d) {
  var selectedsexOption = sex_transformed(
    d3.select("#select_deaths_sex_filter_button").property("value")
  );

  update_sex_change_mortality();
});

d3.select("#select_bubbles_measure_filter_button").on("change", function (d) {
  var selectedMeasureBubblesOption = d3
    .select("#select_bubbles_measure_filter_button")
    .property("value");

  // console.log(
  //   "You have changed the selection to ",
  //   selectedMeasureBubblesOption
  // );

  update_level_three_bubbles();
});

// svg_story.classed("top_ten_table_off", false);
d3.selectAll("#top_ten_burden_table").classed("gbd_top_ten_table", true);

// ! Table of ranks
function showSection_5() {
  svg_story.selectAll(".life_expectancy_figure").remove();
  svg_story.selectAll(".mortality_1_figure").remove();
  svg_story.selectAll(".level_three_bubbles_figure").remove();
  svg_story.selectAll(".rate_over_time_comparison_figure").remove();
  svg_story.selectAll(".comparison_figure").remove();

  d3.selectAll("#vis_placeholder").classed("top_ten_table_off", true);

  d3.selectAll("#top_ten_burden_table").classed("top_ten_table_on", true);
  d3.selectAll("#top_ten_burden_table").classed("top_ten_table_off", false);
  d3.selectAll("#top_ten_table_title").classed(
    "top_ten_table_title_style",
    true
  );
  d3.selectAll("#top_ten_table_title").classed("top_ten_table_off", false);

  // console.log(document.getElementById("top_ten_burden_table").offsetWidth);

  if (document.getElementById("top_ten_burden_table").offsetWidth <= 800) {
    d3.selectAll("#top_ten_burden_table").classed(
      "top_ten_table_maketh_smaller_fonteth",
      true
    );
  }
}

// ! Level 3 bubbles
function showSection_6() {
  d3.selectAll("#vis_placeholder").classed("top_ten_table_off", false);
  svg_story.selectAll(".life_expectancy_figure").remove();
  svg_story.selectAll(".mortality_1_figure").remove();
  svg_story.selectAll(".level_three_bubbles_figure").remove();
  svg_story.selectAll(".rate_over_time_comparison_figure").remove();
  svg_story.selectAll(".comparison_figure").remove();

  d3.selectAll("#top_ten_burden_table").classed("top_ten_table_on", false);
  d3.selectAll("#top_ten_burden_table").classed("top_ten_table_off", true);
  d3.selectAll("#top_ten_table_title").classed(
    "top_ten_table_title_style",
    false
  );
  d3.selectAll("#top_ten_table_title").classed("top_ten_table_off", true);

  svg_story
    .selectAll("#section_vis_placeholder_text")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

    svg_story
    .selectAll("#section_vis_placeholder_text_2")
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

  update_level_three_bubbles();
}

// ! Trends over time
function showSection_7() {
  // console.log("You are in section seven mother flipper");
  svg_story.selectAll(".life_expectancy_figure").remove();
  svg_story.selectAll(".mortality_1_figure").remove();
  svg_story.selectAll(".level_three_bubbles_figure").remove();
  svg_story.selectAll(".rate_over_time_comparison_figure").remove();
  svg_story.selectAll(".comparison_figure").remove();

 svg_story
    .selectAll("#section_vis_placeholder_text")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

 svg_story
    .selectAll("#section_vis_placeholder_text_2")
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

    change_over_time_update_level_two_rates();
}

function showSection_8() {
  svg_story.selectAll(".life_expectancy_figure").remove();
  svg_story.selectAll(".mortality_1_figure").remove();
  svg_story.selectAll(".level_three_bubbles_figure").remove();
  svg_story.selectAll(".rate_over_time_comparison_figure").remove();
  svg_story.selectAll(".comparison_figure").remove();

  svg_story
    .selectAll("#section_vis_placeholder_text")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

    svg_story
    .selectAll("#section_vis_placeholder_text_2")
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

  
// append the axis to the svg_story
svg_story
.append("g")
.attr("class", "comparison_figure comparison_figure_x_axis axis_text")
.attr("transform", "translate(0," + (svg_height - 200) + ")")
.call(d3.axisBottom(x_comparison_rate).tickFormat(d3.format("d")))
.selectAll("text")
.style("text-anchor", "middle")
.attr("opacity", 0)
.transition()
.duration(1000)
.attr("opacity", 1);

svg_story
.append("g")
.attr("class", "comparison_figure comparison_figure_y_axis axis_text")
.attr("transform", "translate(50, 0)")
.call(d3.axisLeft(y_comparison_rate))
.attr("opacity", 0)
.transition()
.duration(1000)
.attr("opacity", 1);

svg_story
.append("text")
.attr("text-anchor", "left")
.attr("class", "comparison_figure figure_caption")
.attr("y", svg_height - 150)
.attr("x", svg_width * 0.05)
.attr("opacity", 0)
.transition()
.duration(1000)
.attr("opacity", 1)
.text( 'The black line and dots represent West Sussex whilst the grey line with no dots represents the comparison area.' );


svg_story
.append("text")
.attr("text-anchor", "left")
.attr("class", "comparison_figure figure_caption")
.attr("y", svg_height - 125)
.attr("x", svg_width * 0.05)
.attr("opacity", 0)
.transition()
.duration(1000)
.attr("opacity", 1)
.text( 'Wider shaded areas around the lines denote greater uncertainty in the estimate.' );

svg_story
.append("text")
.attr("text-anchor", "left")
.attr("class", "comparison_figure figure_caption")
.attr("y", svg_height - 100)
.attr("x", svg_width * 0.05)
.attr("opacity", 0)
.transition()
.duration(1000)
.attr("opacity", 1)
.text( 'If the shaded areas for two lines overlap, it is an indication that the estimates may be statistically similar.' );


update_comparison_figure();
}

function showSection_end() {
  svg_story.selectAll(".life_expectancy_figure").remove();
  svg_story.selectAll(".mortality_1_figure").remove();
  svg_story.selectAll(".level_three_bubbles_figure").remove();
  svg_story.selectAll(".rate_over_time_comparison_figure").remove();

  svg_story
    .selectAll("#section_vis_placeholder_text")
    .transition()
    .duration(750)
    .style("opacity", 0)
    .remove();

  svg_story
    .selectAll("#section_vis_placeholder_text_2")
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

// ! Fucntion to do comparison over time numbers
function change_over_time_update_level_two_numbers() {}

// ! Fucntion to do comparison over time rates
function change_over_time_update_level_two_rates() {
  svg_story.selectAll(".rate_over_time_comparison_figure").remove();

  var selectedMeasureOverTimeOption = d3
    .select("#select_over_tie_rate_measure_filter_button")
    .property("value");

  svg_story
    .append("text")
    .attr("text-anchor", "start")
    .attr("class", "rate_over_time_comparison_figure")
    .attr("y", svg_height * 0.05)
    .attr("x", svg_width * 0.05)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .style("font-weight", "bold")
    .text("Change in rate (all ages) per 100,000 population;");

  svg_story
    .append("text")
    .attr("text-anchor", "start")
    .attr("class", "rate_over_time_comparison_figure")
    .attr("y", svg_height * 0.05 + 17.5)
    .attr("x", svg_width * 0.05)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .style("font-weight", "bold")
    .text(selectedMeasureOverTimeOption + "; West Sussex; persons; 2009-2019;");

    svg_story
    .append("text")
    .attr("text-anchor", "start")
    .attr("class", "rate_over_time_comparison_figure")
    .attr("y", svg_height * 0.95)
    .attr("x", svg_width * 0.05)
    .attr("opacity", 1)
    .text("The 2019 rate per 100,000 population estimates are given in brackets.");


  chosen_over_time_change_df = change_over_time_df.filter(function (d) {
    return d.measure_name === selectedMeasureOverTimeOption;
  });

  abs_min = d3.min(change_over_time_df, function (d) {
    return +d.Percentage_change_on_rate;
  });

  abs_max = d3.max(change_over_time_df, function (d) {
    return +d.Percentage_change_on_rate;
  });

  var x_over_time_rate_change = d3
    .scaleLinear()
    .domain([
      0 - d3.max([Math.abs(abs_min), Math.abs(abs_max)]),
      d3.max([Math.abs(abs_min), Math.abs(abs_max)]),
    ])
    .range([30, svg_width - 30]);

  var y_over_time_rate_change = d3
    .scaleBand()
    .domain(cause_categories)
    .range([50, svg_height - 50])
    .padding(0.2);

  svg_story
    .selectAll("rect")
    .data(chosen_over_time_change_df)
    .enter()
    .append("rect")
    .attr("class", "rate_over_time_comparison_figure")
    .attr("x", function (d) {
      if (d.Percentage_change_on_rate < 0) {
        return x_over_time_rate_change(d.Percentage_change_on_rate); // if % change is negative then the left most position is the 'top' of the bar
      } else {
        return x_over_time_rate_change(0); // if not then the left most position of the bar is 0 (which is actually the middle of the svg width)
      }
    })
    .attr("width", function (d) {
      if (d.Percentage_change_on_rate < 0) {
        return (
          x_over_time_rate_change(d.Percentage_change_on_rate * -1) -
          x_over_time_rate_change(0)
        );
      } else {
        return (
          x_over_time_rate_change(d.Percentage_change_on_rate) -
          x_over_time_rate_change(0)
        );
      }
    })
    .attr("y", function (d) {
      return y_over_time_rate_change(d.cause_name);
    })
    .attr("height", y_over_time_rate_change.bandwidth())
    .style("fill", function (d) {
      return color_cause_group(d.cause_name);
    });

// condition name
  svg_story
    .selectAll(".name")
    .data(chosen_over_time_change_df)
    .enter()
    .append("text")
    .attr("class", "rate_over_time_comparison_figure")
    .attr("x", function (d) {
      return d.Percentage_change_on_rate < 0
        ? x_over_time_rate_change(0) + 5.5
        : x_over_time_rate_change(0) - 5.5;
    })
    .attr("y", function (d) {
      return y_over_time_rate_change(d.cause_name);
    })
    .attr("dy", y_over_time_rate_change.bandwidth() - 2.5)
    .attr("text-anchor", function (d) {
      return d.Percentage_change_on_rate < 0 ? "start" : "end";
    })
    .text(function (d) {
      return d.cause_name;
    });

 // percentage change label  
  svg_story
    .selectAll(".value")
    .data(chosen_over_time_change_df)
    .enter()
    .append("text")
    .attr("class", "rate_over_time_comparison_figure")
    .attr("x", function (d) {
      if (d.Percentage_change_on_rate < 0) {
        return x_over_time_rate_change(d.Percentage_change_on_rate * -1) -
          x_over_time_rate_change(0) >
          20
          ? x_over_time_rate_change(d.Percentage_change_on_rate)
          : x_over_time_rate_change(d.Percentage_change_on_rate) - 1;
      } else {
        return x_over_time_rate_change(d.Percentage_change_on_rate) -
          x_over_time_rate_change(0) >
          20
          ? x_over_time_rate_change(d.Percentage_change_on_rate)
          : x_over_time_rate_change(d.Percentage_change_on_rate) + 1;
      }
    })
    .attr("y", function (d) {
      return y_over_time_rate_change(d.cause_name);
    })
    .attr("dy", y_over_time_rate_change.bandwidth() - 2.5)
    // .attr('text-anchor', 'start')
    .attr("text-anchor", function (d) {
      if (d.Percentage_change_on_rate < 0) {
        return x_over_time_rate_change(d.Percentage_change_on_rate * -1) -
          x_over_time_rate_change(0) >
          190
          ? "start"
          : "end";
      } else {
        return x_over_time_rate_change(d.Percentage_change_on_rate) -
          x_over_time_rate_change(0) >
          190
          ? "end"
          : "start";
      }
    })
    // .style("fill", function (d) {
    //   if (d.Percentage_change_on_rate < 0) {
    //     return x_over_time_rate_change(d.Percentage_change_on_rate * -1) -
    //       x_over_time_rate_change(0) >
    //       90
    //       ? "#000"
    //       : "#000";
    //   } else {
    //     return x_over_time_rate_change(d.Percentage_change_on_rate) -
    //       x_over_time_rate_change(0) >
    //       90
    //       ? "#000"
    //       : "#000";
    //   }
    // })
    .text(function (d) {
      if (d.Percentage_change_on_rate < 0) {
        // add an if else function to say if > 0 then increase, if < 0 then decrease.
        return (
          d3.format(".1%")(Math.abs(d.Percentage_change_on_rate)) + " decrease (to " + d3.format(',.1f')(d.val_2019) + ')'
        );
      } else {
        return (
          d3.format(".1%")(Math.abs(d.Percentage_change_on_rate)) + " increase (to " + d3.format(',.1f')(d.val_2019) + ')'
        );
      }
    });

}

d3.select("#select_over_tie_rate_measure_filter_button").on(
  "change",
  function (d) {
    change_over_time_update_level_two_rates();
  }
);

// ! Function to redraw comparison
function update_comparison_figure() {
svg_story
  .selectAll("#section_vis_placeholder_text")
  .transition()
  .duration(750)
  .style("opacity", 0)
  .remove();

svg_story
  .selectAll("#section_vis_placeholder_text_2")
  .transition()
  .duration(750)
  .style("opacity", 0)
  .remove();

svg_story.selectAll('#rate_comparison_dots')
  .transition()
  .duration(500)
  .attr('opacity', 0)
  .remove()

svg_story.selectAll('.rate_over_time_comparison_lines')
  .transition()
  .duration(500)
  .attr('opacity', 0)
  .remove()

svg_story.selectAll('.comparison_figure_key')
  .remove()

  var selectedAreaComparisonOption = d3
  .select("#select_comparison_area_filter_button")
  .property("value");

var selectedMeasureComparisonOption = d3
  .select("#select_comparison_measure_filter_button")
  .property("value");

var selectedCauseComparisonOption = d3
  .select("#select_comparison_cause_filter_button")
  .property("value");

var selectedAgeComparisonOption = d3
 .select("#select_comparison_age_filter_button")
 .property("value");
 
svg_story
  .append("text")
  .attr("text-anchor", "left")
  .attr("id", "section_vis_placeholder_text")
  .attr("y", svg_height * 0.05)
  .attr("x", svg_width * 0.05)
  .attr("opacity", 0)
  .transition()
  .duration(1000)
  .attr("opacity", 1)
  .style("font-weight", "bold")
  .text(
    "Rate of " +
      selectedMeasureComparisonOption +
      " per 100,000 (" +
      selectedAgeComparisonOption +
      ") in West Sussex"
    );

svg_story
  .append("text")
  .attr("text-anchor", "left")
  .attr("id", "section_vis_placeholder_text_2")
  .attr("x", svg_width * 0.05)
  .attr("y", svg_height * 0.05 + 17.5)
  .attr("opacity", 0)
  .transition()
  .duration(1000)
  .attr("opacity", 1)
  .style("font-weight", "bold")
  .text(
    " compared to " +
    selectedAreaComparisonOption +
    " from the cause category " +
    selectedCauseComparisonOption +
    '.'
    );

  // Add one dot in the legend for each name.
  svg_story.selectAll("myratedots")
  .data(['lower', 'similar', 'higher'])
  .enter()
  .append("circle")
  .attr('class', 'comparison_figure_key comparison_figure')
  //  .attr("cx", 80)
  //  .attr("cy", function(d,i){ return 15 + i*15}) // 100 is where the first dot appears. 25 is the distance between dots
  .attr("cx", function(d,i){ return (svg_width * .055 + 20)  + i * 135}) // 100 is where the first dot appears. 25 is the distance between dots
  .attr('cy', svg_height * .05 + 35)
  .attr("r", 6)
  .style("fill", function(d){ return comparison_colours(d)})
  
  // Add one dot in the legend for each name.
  svg_story.selectAll("myratelabels")
    .data(['Significantly lower', 'Similar', 'Significantly higher'])
    .enter()
    .append("text")
    .attr('class', 'comparison_figure_key comparison_figure')
    .attr("x",  function(d,i){ return (svg_width * .055 + 30)  + i * 135})
    .attr('y', svg_height * .05 + 40)
    .text(function(d){ return d})
    .attr("text-anchor", "left")
    .attr('font-size', '.8rem')
   
chosen_wsx_compare_df = wsx_compare_df.filter(function (d) {
      return d.Measure === selectedMeasureComparisonOption &&
             d.Area === 'West Sussex' &&
             d.Cause === selectedCauseComparisonOption &&
             d.Age === selectedAgeComparisonOption;
    });

chosen_se_compare_df = wsx_compare_df.filter(function (d) {
   return d.Measure === selectedMeasureComparisonOption &&
          d.Area === 'South East England' &&
          d.Cause === selectedCauseComparisonOption &&
          d.Age === selectedAgeComparisonOption;
    });    

chosen_england_compare_df = wsx_compare_df.filter(function (d) {
   return d.Measure === selectedMeasureComparisonOption &&
          d.Area === 'England' &&
          d.Cause === selectedCauseComparisonOption &&
          d.Age === selectedAgeComparisonOption;
    });   
  
all_areas_compare_df = wsx_compare_df.filter(function (d) {
  return d.Measure === selectedMeasureComparisonOption &&
         d.Cause === selectedCauseComparisonOption &&
         d.Age === selectedAgeComparisonOption;
   });   

y_comparison_rate.domain([0, d3.max(all_areas_compare_df, function (d) { return +d.Upper_estimate; })])
    .nice();

svg_story
 .selectAll(".comparison_figure_y_axis")
 .attr("opacity", 1)
 .transition()
 .duration(1000)
 .call(d3.axisLeft(y_comparison_rate));

 svg_story.append("path")
 .datum(chosen_wsx_compare_df)
 .attr('class', 'rate_over_time_comparison_lines rate_over_time_comparison_figure')
 .attr("fill", "none")
 .attr("stroke-width", 1)
 .attr("stroke", function(d) { return comparison_area_colours(d.Area)})
 .attr("d", d3.line()
   .x(function(d) { return x_comparison_rate(d.Year) })
   .y(function(d) { return y_comparison_rate(d.Rate_estimate) })
   )
 .attr('opacity', 0)
 .transition()
 .duration(500)
 .attr('opacity', 1)  



 var tooltip_comparison_fg = d3
 .select("#vis")
 .append("div")
 .style("opacity", 0)
 .attr("class", "tooltips")
 .style("position", "absolute")
 .style("z-index", "10");

// The tooltip function
var showTooltip_comparison_fg = function (d) {
 tooltip_comparison_fg.transition().duration(200).style("opacity", 1);

 tooltip_comparison_fg
   .html(
     "<p>The estimated number of " +
     label_key(d.Measure) + 
     ' as a result of <b>' +
     d.Cause +
     "</b> in " +
     d.Year +
     ' among males and females was <b>' +
     d.label +
     "</b> per 100,000 population (" +
     d.Age +
     ").</p><p>This is <b>" +
     comparison_label(d.Compare_SE) +
     ' compared to the South East region</b> and <b>' +
     comparison_label(d.Compare_Eng) +
     ' compared to England</b>.'
   )
   .style("opacity", 1);
};


if(selectedAreaComparisonOption == 'England') {

// Show confidence interval
svg_story.append("path")
.datum(chosen_england_compare_df)
.attr('class', 'rate_over_time_comparison_lines rate_over_time_comparison_figure')
.attr("fill", "#999")
.attr('opacity', .1)
.attr("stroke", "none")
.attr("d", d3.area()
 .x(function(d) { return x_comparison_rate(d.Year) })
 .y0(function(d) { return y_comparison_rate(d.Lower_estimate) })
 .y1(function(d) { return y_comparison_rate(d.Upper_estimate) })
)

svg_story.append("path")
.datum(chosen_england_compare_df)
.attr('class', 'rate_over_time_comparison_lines rate_over_time_comparison_figure')
.attr("fill", "none")
.attr("stroke", "#999")
.attr("stroke-width", 1)
.attr("d", d3.line()
  .x(function(d) { return x_comparison_rate(d.Year) })
  .y(function(d) { return y_comparison_rate(d.Rate_estimate) })
    )
    .attr('opacity', 0)
    .transition()
    .duration(500)
    .attr('opacity', 1)

// Show WSx confidence interval
svg_story.append("path")
 .datum(chosen_wsx_compare_df)
 .attr('class', 'rate_over_time_comparison_lines rate_over_time_comparison_figure')
 .attr("fill", "#30336B")
 .attr('opacity', .1)
 .attr("stroke", "none")
 .attr("d", d3.area()
  .x(function(d) { return x_comparison_rate(d.Year) })
  .y0(function(d) { return y_comparison_rate(d.Lower_estimate) })
  .y1(function(d) { return y_comparison_rate(d.Upper_estimate) })
 )
      
svg_story.selectAll("comparison_dots")
 .data(chosen_wsx_compare_df)
 .enter()
 .append("circle")
 .attr('class', 'rate_over_time_comparison_figure')
 .attr('id', 'rate_comparison_dots')
 .attr("cx", function(d) { return x_comparison_rate(d.Year) } )
 .attr("cy", function(d) { return y_comparison_rate(d.Rate_estimate) } )
 .attr("r", 6)
 .attr("fill", function(d) {return comparison_colours(d.Compare_Eng ) } )
 .attr('opacity', 0)
 .transition()
 .duration(1000)
 .attr('opacity', 1)
      
    svg_story
    .selectAll("#rate_comparison_dots")
    .on("mouseover", function () {
      return tooltip_comparison_fg.style("visibility", "visible");
      })
    .on("mousemove", showTooltip_comparison_fg)
    .on("mouseout", function () {
      return tooltip_comparison_fg.style("visibility", "hidden");
      });  
    

}

if(selectedAreaComparisonOption == 'South East England') {


// Show confidence interval
svg_story.append("path")
.datum(chosen_se_compare_df)
.attr('class', 'rate_over_time_comparison_lines rate_over_time_comparison_figure')
.attr("fill", "#999")
.attr('opacity', .1)
.attr("stroke", "none")
.attr("d", d3.area()
 .x(function(d) { return x_comparison_rate(d.Year) })
 .y0(function(d) { return y_comparison_rate(d.Lower_estimate) })
 .y1(function(d) { return y_comparison_rate(d.Upper_estimate) })
)

svg_story.append("path")
 .datum(chosen_se_compare_df)
 .attr('class', 'rate_over_time_comparison_lines rate_over_time_comparison_figure')
 .attr("fill", "none")
 .attr("stroke-width", 1)
 .attr("d", d3.line()
 .x(function(d) { return x_comparison_rate(d.Year) })
 .y(function(d) { return y_comparison_rate(d.Rate_estimate) })
  ) 
  .attr("stroke", '#999')
  .attr('opacity', 0)
  .transition()
  .duration(500)
  .attr('opacity', 1)
 
// Show WSx confidence interval
svg_story.append("path")
 .datum(chosen_wsx_compare_df)
 .attr('class', 'rate_over_time_comparison_lines rate_over_time_comparison_figure')
 .attr("fill", "#30336B")
 .attr('opacity', .1)
 .attr("stroke", "none")
 .attr("d", d3.area()
  .x(function(d) { return x_comparison_rate(d.Year) })
  .y0(function(d) { return y_comparison_rate(d.Lower_estimate) })
  .y1(function(d) { return y_comparison_rate(d.Upper_estimate) })
 )
  
svg_story.selectAll("comparison_dots")
 .data(chosen_wsx_compare_df)
 .enter()
 .append("circle")
 .attr('class', 'rate_over_time_comparison_figure')
 .attr('id', 'rate_comparison_dots')
 .attr("cx", function(d) { return x_comparison_rate(d.Year) } )
 .attr("cy", function(d) { return y_comparison_rate(d.Rate_estimate) } )
 .attr("r", 6)
 .attr("fill", function(d) {return comparison_colours(d.Compare_SE) } )
 .attr('opacity', 0)
 .transition()
 .duration(1000)
 .attr('opacity', 1)

svg_story
 .selectAll("#rate_comparison_dots")
 .on("mouseover", function () {
   return tooltip_comparison_fg.style("visibility", "visible");
   })
 .on("mousemove", showTooltip_comparison_fg)
 .on("mouseout", function () {
   return tooltip_comparison_fg.style("visibility", "hidden");
   });  
  
 }


}

d3.select("#select_comparison_area_filter_button").on("change", function (d) {
  update_comparison_figure();
});

d3.select("#select_comparison_measure_filter_button").on(
  "change",
  function (d) {
    update_comparison_figure();
  }
);

d3.select("#select_comparison_cause_filter_button").on(
  "change",
  function (d) {
    update_comparison_figure();
  }
);

d3.select("#select_comparison_age_filter_button").on(
  "change",
  function (d) {
    update_comparison_figure();
  }
);


// ! Function to redraw mortality top ten
// When the drop down menu button for sex is changed run this (basically filter the data for mortality, sort by rank and keep the top ten). This function is called again any time you go back into section four.

// TODO We only want this to work when the user is in the section on deaths. If they click it when they are outside of the section it will overwrite whatever svg is there.
function update_sex_change_mortality() {
  svg_story.selectAll(".mortality_1_figure_title").remove();

  var selectedsexOption = sex_transformed(
    d3.select("#select_deaths_sex_filter_button").property("value")
  );

  var chosen_sex_mortality_df = rank_df_number
    .filter(function (d) {
      return d.sex === selectedsexOption;
    })
    .sort(function (a, b) {
      return +a.Deaths_rank - +b.Deaths_rank;
    })
    .filter(function (d, i) {
      return i < 10;
    });

  // reconfigure the y axis range
  y_top_ten_mortality
    .domain([
      0,
      d3.max(chosen_sex_mortality_df, function (d) {
        return +d.Deaths_value;
      }),
    ])
    .nice(); // Add the ceiling

  x_top_ten.domain(
    d3
      .map(chosen_sex_mortality_df, function (d) {
        return shortened_causes(d.cause);
      })
      .keys()
  );

  svg_story
    .selectAll(".mortality_1_figure_x_axis")
    .attr("opacity", 1)
    // .transition()
    // .duration(1000)
    .call(d3.axisBottom(x_top_ten))
    .selectAll("text")
    .style("text-anchor", "end")
    .attr("dx", "-.8em")
    .attr("dy", ".15em")
    .style("font-size", ".8rem")
    .attr("transform", function (d) {
      return "rotate(-45)";
    });

  // Redraw axis
  svg_story
    .selectAll(".mortality_1_figure_y_axis")
    .attr("opacity", 1)
    .transition()
    .duration(1000)
    // .style("font-size", ".8rem")
    .call(d3.axisLeft(y_top_ten_mortality));
  // .style("font-size", ".8rem");

  svg_story
    .append("text")
    .attr("text-anchor", "left")
    .attr(
      "class",
      "mortality_1_figure mortality_1_figure_title chart_title_text"
    )
    .attr("y", 50)
    .attr("x", svg_width * 0.05)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .text("Top ten causes of death (level two groupings);");

  svg_story
    .append("text")
    .attr("text-anchor", "left")
    .attr(
      "class",
      "mortality_1_figure mortality_1_figure_title chart_title_text"
    )
    .attr("y", 65)
    .attr("x", svg_width * 0.05)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .text(
      "all ages; " +
        selectedsexOption
          .replace("Both", "overall among both males and female")
          .toLowerCase() +
        "s; " +
        area_x
    );

  var tooltip_fg_deaths = d3
    .select("#vis")
    .append("div")
    .style("opacity", 0)
    .attr("class", "tooltips")
    .style("position", "absolute")
    .style("z-index", "10");

  // The tooltip function
  var showTooltip_top_ten_deaths = function (d) {
    tooltip_fg_deaths.transition().duration(200).style("opacity", 1);

    tooltip_fg_deaths
      .html(
        "<p>The estimated number of deaths as a result of <b>" +
          d.cause +
          "</b> in " +
          area_x +
          " in 2019 among " +
          d.sex.toLowerCase().replace("both", "both males and female") +
          "s was <b>" +
          d3.format(",.0f")(d.Deaths_value) +
          "</b>.</p>"
      )
      .style("opacity", 1);
    // .style("top", (event.pageY - 10) + "px")
    // .style("left", (event.pageX + 10) + "px")
  };

  // Create the bars_df variable
  svg_mort = svg_story.selectAll("rect").data(chosen_sex_mortality_df);

  svg_mort
    .enter()
    .append("rect")
    .merge(svg_mort)
    .attr("class", "mortality_1_figure")
    .attr("id", "mortality_bars")
    .transition()
    .duration(1000)
    .attr("x", function (d) {
      return x_top_ten(shortened_causes(d.cause));
    })
    .attr("width", x_top_ten.bandwidth())
    .attr("height", function (d) {
      return svg_height - 200 - y_top_ten_mortality(d.Deaths_value);
    })
    .attr("y", function (d) {
      return y_top_ten_mortality(d.Deaths_value);
    })
    .style("fill", function (d) {
      return color_cause_group(d.cause);
    });

  svg_mort
    .enter()
    .append("rect")
    .merge(svg_mort)
    .on("mouseover", function () {
      return tooltip_fg_deaths.style("visibility", "visible");
    })
    .on("mousemove", showTooltip_top_ten_deaths)
    .on("mouseout", function () {
      return tooltip_fg_deaths.style("visibility", "hidden");
    });

  svg_mort.exit().remove();
}

// ! Function to redraw bubbles
// When the drop down menu button for measure is changed run this (basically filter the data for measure and redraw bubbles). This function is called again any time you go back into section four.

level_three_nodes = svg_story;

// TODO We only want this to work when the user is in the section on deaths. If they click it when they are outside of the section it will overwrite whatever svg is there.
function update_level_three_bubbles() {
  svg_size_key.selectAll(".legend_key_class").remove();
  svg_story.selectAll(".level_three_bubbles_figure").remove();

  var selectedMeasureBubblesOption = d3
    .select("#select_bubbles_measure_filter_button")
    .property("value");

  chosen_level_three_df = level_three_cause_df
    .filter(function (d) {
      return (
        d.sex_name === "Both" && d.measure_name === selectedMeasureBubblesOption
      );
    })
    .sort(function (a, b) {
      return d3.descending(a["parent_cause"], b["parent_cause"]);
    });

  // Grab the lowest number of deaths
  var min_value = d3.min(chosen_level_three_df, function (d) {
    return +d.val;
  });

  // Grab the highest number of value
  var max_value = d3.max(chosen_level_three_df, function (d) {
    return +d.val;
  });

  // Key size
  var valuesToShow = [10, max_value / 4, max_value / 2, max_value];

  // Size scale for bubbles - The scaleSqrt scale is useful for sizing circles by area (rather than radius). When using circle size to represent data, it’s considered better practice to set the area, rather than the radius proportionally to the data.
  var bubble_size = d3.scaleSqrt().domain([0, max_value]).range([0.1, 45]);

  svg_size_key
    .selectAll("chart_legend")
    .data(valuesToShow)
    .enter()
    .append("circle")
    .attr("cx", xCircle)
    // .attr("cy", function (d) {
    //   return yCircle - bubble_size(d);
    // })
    .attr("cy", function (d) {
      return yCircle - bubble_size(d) - 90;
    })
    .attr("r", function (d) {
      return bubble_size(d);
    })
    .style("fill", "none")
    .attr("stroke", "black")
    .attr("class", "legend_key_class");

  // Add svg_size_key: segments
  svg_size_key
    .selectAll("legend")
    .data(valuesToShow)
    .enter()
    .append("line")
    .attr("x1", function (d) {
      return xCircle + bubble_size(d);
    })
    .attr("x2", xLabel)
    .attr("y1", function (d) {
      return yCircle - bubble_size(d) - 90;
    })
    .attr("y2", function (d) {
      return yCircle - bubble_size(d) - 90;
    })
    .attr("stroke", "black")
    .style("stroke-dasharray", "2,2")
    .attr("class", "legend_key_class");

  // Add svg_size_key: labels
  svg_size_key
    .selectAll("legend")
    .data(valuesToShow)
    .enter()
    .append("text")
    .attr("x", xLabel)
    .attr("y", function (d) {
      return yCircle - bubble_size(d) - 90;
    })
    .text(function (d) {
      return (
        d3.format(",.0f")(d) + " " + label_key(selectedMeasureBubblesOption)
      );
    })
    .attr("font-size", 11)
    .attr("alignment-baseline", "top")
    .attr("class", "legend_key_class");

  svg_story
    .append("text")
    .attr("text-anchor", "start")
    .attr("class", "level_three_bubbles_figure")
    .attr("y", svg_height * 0.05)
    .attr("x", svg_width * 0.05)
    .attr("opacity", 0)
    .transition()
    .duration(1000)
    .attr("opacity", 1)
    .style("font-weight", "bold")
    .text(selectedMeasureBubblesOption + "; West Sussex; 2019");

  var forceXSplit = d3
    .forceX(function (d) {
      if (d["parent_cause"] === "Neoplasms") {
        return svg_width * 0.25;
      } else if (d["parent_cause"] === "Cardiovascular diseases") {
        return svg_width * 0.25;
      } else if (d["parent_cause"] === "Chronic respiratory diseases") {
        return svg_width * 0.5;
      } else if (d["parent_cause"] === "Neurological disorders") {
        return svg_width * 0.5;
      } else if (d["parent_cause"] === "Musculoskeletal disorders") {
        return svg_width * 0.75;
      } else {
        return svg_width * 0.75;
      }
    })
    .strength(0.1);

  var forceYSplit = d3
    .forceY(function (d) {
      if (d["parent_cause"] === "Neoplasms") {
        return svg_height * 0.35;
      } else if (d["parent_cause"] === "Cardiovascular diseases") {
        return svg_height * 0.8;
      } else if (d["parent_cause"] === "Chronic respiratory diseases") {
        return svg_height * 0.35;
      } else if (d["parent_cause"] === "Neurological disorders") {
        return svg_height * 0.8;
      } else if (d["parent_cause"] === "Musculoskeletal disorders") {
        return svg_height * 0.35;
      } else {
        return svg_height * 0.8;
      }
    })
    .strength(0.1);

  // Features of the forces applied to the nodes:
  var simulation = d3
    .forceSimulation()
    .force(
      "center",
      d3
        .forceCenter()
        .x(svg_width * 0.575)
        .y(svg_height * 0.6)
    )
    .force("charge", d3.forceManyBody().strength(2))
    // Force that avoids circle overlapping
    .force(
      "collide",
      d3
        .forceCollide()
        .strength(5)
        .radius(function (d) {
          return bubble_size(d.val) + 1;
        })
        .iterations(1)
    );

  var tooltip_level_three_bubbles = d3
    .select("#vis")
    .append("div")
    .style("opacity", 0)
    .attr("class", "tooltips")
    .style("position", "absolute")
    .style("z-index", "10");

  // This creates the function for what to do when someone moves the mouse over a circle (e.g. move the tooltip in relation to the mouse cursor).
  var showTooltip_level_three_bubbles = function (d) {
    tooltip_level_three_bubbles
      .html(
        "<p>In 2019 there were an estimated <b>" +
          d3.format(",.0f")(d.val) +
          "</b> " +
          label_key(d.measure_name) +
          " among " +
          d.sex_name.toLowerCase().replace("both", "both males and female") +
          "s caused by <b>" +
          d.cause_name.toLowerCase() +
          "</b>. This is part of the " +
          d.parent_cause.toLowerCase() +
          " disease group.</p>"
      )
      .style("opacity", 1);
  };

  // Initialize the circle
  node = svg_story
    .append("g")
    .selectAll("circle")
    .data(chosen_level_three_df)
    .enter()
    .append("circle")
    .attr("class", "level_three_bubbles_figure level_three_bubbles")
    .attr("r", function (d) {
      return bubble_size(d.val);
    })
    .style("fill", function (d) {
      return color_cause_group(d["parent_cause"]);
    })
    .style("stroke", "#fff")
    .style("fill-opacity", 1)
    .on("mouseover", function () {
      return tooltip_level_three_bubbles.style("visibility", "visible");
    })
    .on("mousemove", showTooltip_level_three_bubbles)
    .on("mouseout", function () {
      return tooltip_level_three_bubbles.style("visibility", "hidden");
    })
    .call(
      d3
        .drag()
        .on("start", dragstarted)
        .on("drag", dragged)
        .on("end", dragended)
    );

  simulation.nodes(chosen_level_three_df).on("tick", function (d) {
    node
      .attr("cx", function (d) {
        return d.x;
      })
      .attr("cy", function (d) {
        return d.y;
      });
  });

  simulation
    .force("x", forceXSplit)
    .force("y", forceYSplit)
    .force(
      "collide",
      d3
        .forceCollide()
        .strength(0.5)
        .radius(function (d) {
          return bubble_size(d.val) + 1;
        })
    );
  // .alphaTarget(0);

  function dragstarted(d) {
    if (!d3.event.active) simulation.alphaTarget(0.05).restart();
    d.fx = d.x;
    d.fy = d.y;
  }

  function dragged(d) {
    d.fx = d3.event.x;
    d.fy = d3.event.y;
  }

  function dragended(d) {
    if (!d3.event.active) simulation.alphaTarget(0.05);
    d.fx = null;
    d.fy = null;
  }

  if (svg_width > 720) {
    // Labels (this might break)
    svg_story
      .append("text")
      .attr("text-anchor", "start")
      .attr("class", "level_three_bubbles_figure")
      .attr("y", svg_height * 0.1)
      .attr("x", svg_width * 0.15)
      .attr("opacity", 0)
      .transition()
      .duration(1000)
      .attr("opacity", 1)
      // .style("font-weight", "bold")
      .text("Neoplasms");

    svg_story
      .append("text")
      .attr("text-anchor", "middle")
      .attr("class", "level_three_bubbles_figure")
      .attr("y", svg_height * 0.1)
      .attr("x", svg_width * 0.5)
      .attr("opacity", 0)
      .transition()
      .duration(1000)
      .attr("opacity", 1)
      // .style("font-weight", "bold")
      .text("Chronic respiratory diseases");

    svg_story
      .append("text")
      .attr("text-anchor", "end")
      .attr("class", "level_three_bubbles_figure")
      .attr("y", svg_height * 0.1)
      .attr("x", svg_width * 0.85)
      .attr("opacity", 0)
      .transition()
      .duration(1000)
      .attr("opacity", 1)
      // .style("font-weight", "bold")
      .text("Musculoskeletal disorders");

    svg_story
      .append("text")
      .attr("text-anchor", "start")
      .attr("class", "level_three_bubbles_figure")
      .attr("y", svg_height * 0.5)
      .attr("x", svg_width * 0.15)
      .attr("opacity", 0)
      .transition()
      .duration(1000)
      .attr("opacity", 1)
      // .style("font-weight", "bold")
      .text("Cardiovascular diseases");

    svg_story
      .append("text")
      .attr("text-anchor", "middle")
      .attr("class", "level_three_bubbles_figure")
      .attr("y", svg_height * 0.5)
      .attr("x", svg_width * 0.5)
      .attr("opacity", 0)
      .transition()
      .duration(1000)
      .attr("opacity", 1)
      // .style("font-weight", "bold")
      .text("Neurological disorders");

    svg_story
      .append("text")
      .attr("text-anchor", "end")
      .attr("class", "level_three_bubbles_figure")
      .attr("y", svg_height * 0.5)
      .attr("x", svg_width * 0.85)
      .attr("opacity", 0)
      .transition()
      .duration(1000)
      .attr("opacity", 1)
      // .style("font-weight", "bold")
      .text("Other conditions/disorders");
  }
}
