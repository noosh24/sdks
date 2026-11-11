#include <cmath>
#include <limits>

#include "mock.hpp"

using namespace std::chrono;
using namespace std::chrono_literals;

TEST(Where, BuildsAndOnlyConditions)
{
    auto text = noosh24::where()
                    .eq("category", "Salads")
                    .ne("station", "")
                    .gt("price", 4.75)
                    .lte("prepMinutes", 15)
                    .eq("vegetarian", false)
                    .gte("createdAt", noosh24::OffsetDateTime{local_days{2026y / November / 1} + 18h, 4h})
                    .lt("price", 20.0)
                    .in("id", {"7f0c", "O'Neil", 3})
                    .str();

    EXPECT_EQ(text, "category = 'Salads' AND station != '' AND price > 4.75 AND prepMinutes <= 15 AND vegetarian = "
                    "false AND createdAt >= '2026-11-01T18:00:00+04:00' AND price < 20 AND id in ('7f0c', "
                    "'O''Neil', 3)");
}

TEST(Where, DatesAndOtherValues)
{
    std::string text = noosh24::where()
                           .lt("visitedOn", 2026y / November / 2)
                           .gte("startsAt", sys_days{2026y / November / 20} + 15h + 30min + 250ms)
                           .eq("updatedAt", noosh24::OffsetDateTime{local_days{2026y / March / 1} + 1h, -(3h + 30min)})
                           .gt("lowStock", 0.0001)
                           .gt("costPerUnit", 1.5e-05)
                           .ne("name", std::string("Chef's"))
                           .ne("zone", std::string_view("Terrace"))
                           .gt("stock", 7U)
                           .lt("value", -0.0);

    EXPECT_EQ(text, "visitedOn < '2026-11-02' AND startsAt >= '2026-11-20T15:30:00.250000+00:00' AND updatedAt = "
                    "'2026-03-01T01:00:00-03:30' AND lowStock > 0.0001 AND costPerUnit > 1.5e-05 AND name != "
                    "'Chef''s' AND zone != 'Terrace' AND stock > 7 AND value < 0");
}

TEST(Where, EmptyIsEmptyString)
{
    EXPECT_EQ(noosh24::Where{}.str(), "");
    EXPECT_TRUE(noosh24::Where{}.empty());
}

TEST(Where, RejectsBadInput)
{
    EXPECT_THROW(noosh24::where().eq("price = 1 OR 1", 1), std::invalid_argument);
    EXPECT_THROW(noosh24::where().eq("1price", 1), std::invalid_argument);
    EXPECT_THROW(noosh24::where().eq("", 1), std::invalid_argument);
    EXPECT_THROW(noosh24::where().in("id", std::vector<noosh24::Literal>{}), std::invalid_argument);
    EXPECT_THROW(noosh24::where().gt("price", std::nan("")), std::invalid_argument);
    EXPECT_THROW(noosh24::where().gt("price", std::numeric_limits<double>::infinity()), std::invalid_argument);
    EXPECT_THROW(noosh24::where().eq("note", nullptr), std::invalid_argument);
    EXPECT_THROW(noosh24::where().eq("note", static_cast<const char*>(nullptr)), std::invalid_argument);
    EXPECT_THROW(noosh24::where().eq("day", 2026y / February / 30), std::invalid_argument);
    EXPECT_NO_THROW(noosh24::where().eq("menu.category_2", 1));
}
