module Bottom

import public IOProcess

-- Compile to C++ and save
bquestX : List String -> Bool -> String -> FileIO () ()
bquestX file bra cpf =
    case parse (some bParser) (concat file) of
      Left err => putStrLn $ "Failed to parse: " ++ err
      Right v  => let sln = splitLines $ finalize v bra
                  in save sln cpf

-- coma intercalate
intercalateC : List String -> String
intercalateC [] = ""
intercalateC [x] = x
intercalateC (x :: xs) = x ++ "," ++ intercalateC xs

-- recursive rm -rf
cleanUp : List String -> { [SYSTEM] } Eff ()
cleanUp []      = return ()
cleanUp (x::xs) = do sys $ "rm -rf " ++ x
                     cleanUp xs

-- flex
lex : String -> String -> { [SYSTEM] } Eff ()
lex cc f = sys $ cc ++ " " ++ f

-- bison
parse : String -> String -> { [SYSTEM] } Eff ()
parse cc f = sys $ cc ++ " -y -d " ++ f

-- compile to executable
bquestY : String -> String -> List String -> { [SYSTEM] } Eff ()
bquestY cc f xs = let cpps = intercalateC $ filter (isSuffixOf "cpp") xs
               in do sys $ cc ++ " -I . -o " ++ f ++ " " ++ cpps ++ " -O3 -Wall -std=c++1y"
                     cleanUp xs

-- just compile with -c flag
bquestYL : String -> String -> List String -> { [SYSTEM] } Eff ()
bquestYL cc f xs = let cpps = intercalateC $ filter (isSuffixOf "cpp") xs
                in do sys $ cc ++ " -I . -c -o " ++ f ++ " " ++ cpps ++ " -O3 -Wall -std=c++1y"
                      cleanUp xs

-- Compile to C++ and save with bquestX
bcompileX : String -> String -> FileIO () ()
bcompileX f cpf = case !(open f Read) of
                      True  => do dat <- readFile
                                  close {- =<< -}
                                  bquestX dat True cpf
                      False => putStrLn ("File not found :" ++ f)

-- Src compile w/o Effect!
srcCompileNoEffect : String -> String
srcCompileNoEffect x =
    case rff # 1 of
        Just f => let ext = case head' rff of
                              Just "cxx"  => "cpp"
                              Just "hxx"  => "hpp"
                              Just "h"    => "hpp"
                              _           => "WTF"
                  in f ++ "." ++ ext
        _ => ""
  where rff : List String
        rff = reverse $ with String splitOn '.' x

-- Building source Point
srcCompile : String -> FileIO () ()
srcCompile x = do 
    putStr $ "src: " ++ x
    case srcCompileNoEffect x of
        ""  => putStrLn "What?"
        cpf => do putStrLn $ " -> " ++ cpf
                  bcompileX x cpf

-- Building project Point
buildPoint : (String, String) -> List String -> String -> FileIO () ()
buildPoint ("lex",x) _ _  = lex "flex" x
buildPoint ("parse",x) _ _ = parse "bison" x
buildPoint ("src",x) m _ = srcCompile x
buildPoint ("out",x) m cc = bquestY cc x m
buildPoint ("lib",x) m cc = bquestYL cc x m
buildPoint (_,_) _ _      = putStrLn "What!?"

-- Recursive project Build
buildProject : List (String, String) -> List String -> String -> FileIO () ()
buildProject [] _ _               = putStrLn "There is nothing to do"
buildProject _ [] _               = putStrLn "No modules to compile"
buildProject [(t,x)] m cc         = buildPoint (t,x) m cc
buildProject (("cc",x) :: xs) m _ = buildProject xs m x
buildProject ((t,x) :: xs) m cc   = do buildProject [(t,x)] m cc
                                       buildProject xs m cc
