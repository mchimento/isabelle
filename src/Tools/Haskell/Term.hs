{- generated by Isabelle -}

{-  Title:      Tools/Haskell/Term.hs
    Author:     Makarius
    LICENSE:    BSD 3-clause (Isabelle)

Lambda terms, types, sorts.
-}

module Isabelle.Term (
  Indexname,

  Sort, dummyS,

  Typ(..), dummyT, Term(..))
where

type Indexname = (String, Int)


type Sort = [String]

dummyS :: Sort
dummyS = [""]


data Typ =
    Type (String, [Typ])
  | TFree (String, Sort)
  | TVar (Indexname, Sort)
  deriving Show

dummyT :: Typ
dummyT = Type ("dummy", [])


data Term =
    Const (String, Typ)
  | Free (String, Typ)
  | Var (Indexname, Typ)
  | Bound Int
  | Abs (String, Typ, Term)
  | App (Term, Term)
  deriving Show
