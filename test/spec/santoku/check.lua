 local assert = require("luassert")
 local test = require("santoku.test")
 local check = require("santoku.check")

 test("err", function ()

   test("check(...)", function ()
     local ok, e = pcall(function ()
       check(false, "hi")
     end)
     assert(ok == false)
     assert(e == "hi")
   end)

   test("check:exists(...)", function ()
     local ok, e = pcall(function ()
       check:exists("hi")
       return "hi"
     end)
     assert(ok == true)
     assert(e == "hi")
   end)

   test("check:wrap(...) with check:handler(...)", function ()

     local ok, err = check:wrap(function (check)
       check:handler(function (err)
         assert(err == "hi")
         return false, err
       end)
       check(false, "hi")
     end)

     assert(ok == false)
     assert(err == "hi")

   end)

   test("check:wrap(...) with check:handler(...) recover", function ()

     local ok, x = check:wrap(function (check)
       check:handler(function (err)
         assert(err == "hi")
         return true, "bye"
       end)
       local a = check(false, "hi")
       assert(a == "bye")
       return a
     end)

     assert(ok == true)
     assert(x == "bye")

   end)

   test("check:wrap(...) with check:sub(...) recover", function ()

     local ok, a, b = check:wrap(function (check)
       local check_a = check:sub(function (err)
         assert(err == "one")
         return true, "one+"
       end)
       local check_b = check:sub(function (err)
         assert(err == "two")
         return true, "two+"
       end)
       local a = check_a(false, "one")
       local b = check_b(false, "two")
       assert(a == "one+")
       assert(b == "two+")
       return a, b
     end)

     assert(ok == true)
     assert(a == "one+")
     assert(b == "two+")

   end)

   test("check:wrap(...) with check:sub(...) failure", function ()

     local ok, a = check:wrap(function (check)
       local check_a = check:sub(function (err)
         assert(err == "one")
         return false, "one+"
       end)
       check_a(false, "one")
       assert(false)
     end)

     assert(ok == false)
     assert(a == "one+")

   end)

   test("check:wrap(...) with check:sub(...) failure", function ()

     local ok, a = check:wrap(function (check)
       local check_a = check:sub(function (err)
         assert(err == "one")
         return false, "one+"
       end)
       check_a(false, "one")
       assert(false)
     end)

     assert(ok == false)
     assert(a == "one+")

   end)

   test("check:wrap(...) with check:sub(...) exists", function ()

     local ok, a = check:wrap(function (check)
       local check_a = check:sub(function (err)
         assert(err == "one")
         return false, "one+"
       end)
       local a = check_a:exists("one")
       assert(a == "one")
       return "two"
     end)

     assert(ok == true)
     assert(a == "two")

   end)

 end)
