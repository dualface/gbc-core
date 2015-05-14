require("framework.functions")

local _TEST_SUIT_NAME = "framework_functions"

BEGIN_CASE(_TEST_SUIT_NAME, "THROW_AN_ERROR_DEBUG_GT_1")
    DEBUG = 2
    EXPECT_ERROR("test error", throw, "test error")  
END_CASE()

BEGIN_CASE(_TEST_SUIT_NAME, "THROW_AN_ERROR_DEBUG_LE_1")
    DEBUG = 0
    EXPECT_ERROR("test error", throw, "test error")  
END_CASE()

BEGIN_CASE(_TEST_SUIT_NAME, "CHECKNUMBER_OK")
    EXPECT_EQ(5, checknumber(5))
END_CASE()

BEGIN_CASE(_TEST_SUIT_NAME, "CHECKNUMBER_NOK")
    EXPECT_EQ(0, checknumber("string"))
END_CASE()
