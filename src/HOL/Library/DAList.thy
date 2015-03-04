(*  Title:      HOL/Library/DAList.thy
    Author:     Lukas Bulwahn, TU Muenchen
*)

section \<open>Abstract type of association lists with unique keys\<close>

theory DAList
imports AList
begin

text \<open>This was based on some existing fragments in the AFP-Collection framework.\<close>

subsection \<open>Preliminaries\<close>

lemma distinct_map_fst_filter:
  "distinct (map fst xs) \<Longrightarrow> distinct (map fst (List.filter P xs))"
  by (induct xs) auto


subsection \<open>Type @{text "('key, 'value) alist" }\<close>

typedef ('key, 'value) alist = "{xs :: ('key \<times> 'value) list. (distinct \<circ> map fst) xs}"
  morphisms impl_of Alist
proof
  show "[] \<in> {xs. (distinct o map fst) xs}"
    by simp
qed

setup_lifting type_definition_alist

lemma alist_ext: "impl_of xs = impl_of ys \<Longrightarrow> xs = ys"
  by (simp add: impl_of_inject)

lemma alist_eq_iff: "xs = ys \<longleftrightarrow> impl_of xs = impl_of ys"
  by (simp add: impl_of_inject)

lemma impl_of_distinct [simp, intro]: "distinct (map fst (impl_of xs))"
  using impl_of[of xs] by simp

lemma Alist_impl_of [code abstype]: "Alist (impl_of xs) = xs"
  by (rule impl_of_inverse)


subsection \<open>Primitive operations\<close>

lift_definition lookup :: "('key, 'value) alist \<Rightarrow> 'key \<Rightarrow> 'value option" is map_of  .

lift_definition empty :: "('key, 'value) alist" is "[]"
  by simp

lift_definition update :: "'key \<Rightarrow> 'value \<Rightarrow> ('key, 'value) alist \<Rightarrow> ('key, 'value) alist"
  is AList.update
  by (simp add: distinct_update)

(* FIXME: we use an unoptimised delete operation. *)
lift_definition delete :: "'key \<Rightarrow> ('key, 'value) alist \<Rightarrow> ('key, 'value) alist"
  is AList.delete
  by (simp add: distinct_delete)

lift_definition map_entry ::
    "'key \<Rightarrow> ('value \<Rightarrow> 'value) \<Rightarrow> ('key, 'value) alist \<Rightarrow> ('key, 'value) alist"
  is AList.map_entry
  by (simp add: distinct_map_entry)

lift_definition filter :: "('key \<times> 'value \<Rightarrow> bool) \<Rightarrow> ('key, 'value) alist \<Rightarrow> ('key, 'value) alist"
  is List.filter
  by (simp add: distinct_map_fst_filter)

lift_definition map_default ::
    "'key \<Rightarrow> 'value \<Rightarrow> ('value \<Rightarrow> 'value) \<Rightarrow> ('key, 'value) alist \<Rightarrow> ('key, 'value) alist"
  is AList.map_default
  by (simp add: distinct_map_default)


subsection \<open>Abstract operation properties\<close>

(* FIXME: to be completed *)

lemma lookup_empty [simp]: "lookup empty k = None"
  by (simp add: empty_def lookup_def Alist_inverse)

lemma lookup_delete [simp]: "lookup (delete k al) = (lookup al)(k := None)"
  by (simp add: lookup_def delete_def Alist_inverse distinct_delete delete_conv')


subsection \<open>Further operations\<close>

subsubsection \<open>Equality\<close>

instantiation alist :: (equal, equal) equal
begin

definition "HOL.equal (xs :: ('a, 'b) alist) ys == impl_of xs = impl_of ys"

instance
  by default (simp add: equal_alist_def impl_of_inject)

end


subsubsection \<open>Size\<close>

instantiation alist :: (type, type) size
begin

definition "size (al :: ('a, 'b) alist) = length (impl_of al)"

instance ..

end


subsection \<open>Quickcheck generators\<close>

notation fcomp (infixl "\<circ>>" 60)
notation scomp (infixl "\<circ>\<rightarrow>" 60)

definition (in term_syntax)
  valterm_empty :: "('key :: typerep, 'value :: typerep) alist \<times> (unit \<Rightarrow> Code_Evaluation.term)"
  where "valterm_empty = Code_Evaluation.valtermify empty"

definition (in term_syntax)
  valterm_update :: "'key :: typerep \<times> (unit \<Rightarrow> Code_Evaluation.term) \<Rightarrow>
  'value :: typerep \<times> (unit \<Rightarrow> Code_Evaluation.term) \<Rightarrow>
  ('key, 'value) alist \<times> (unit \<Rightarrow> Code_Evaluation.term) \<Rightarrow>
  ('key, 'value) alist \<times> (unit \<Rightarrow> Code_Evaluation.term)" where
  [code_unfold]: "valterm_update k v a = Code_Evaluation.valtermify update {\<cdot>} k {\<cdot>} v {\<cdot>}a"

fun (in term_syntax) random_aux_alist
where
  "random_aux_alist i j =
    (if i = 0 then Pair valterm_empty
     else Quickcheck_Random.collapse
       (Random.select_weight
         [(i, Quickcheck_Random.random j \<circ>\<rightarrow> (\<lambda>k. Quickcheck_Random.random j \<circ>\<rightarrow>
           (\<lambda>v. random_aux_alist (i - 1) j \<circ>\<rightarrow> (\<lambda>a. Pair (valterm_update k v a))))),
          (1, Pair valterm_empty)]))"

instantiation alist :: (random, random) random
begin

definition random_alist
where
  "random_alist i = random_aux_alist i i"

instance ..

end

no_notation fcomp (infixl "\<circ>>" 60)
no_notation scomp (infixl "\<circ>\<rightarrow>" 60)

instantiation alist :: (exhaustive, exhaustive) exhaustive
begin

fun exhaustive_alist ::
  "(('a, 'b) alist \<Rightarrow> (bool \<times> term list) option) \<Rightarrow> natural \<Rightarrow> (bool \<times> term list) option"
where
  "exhaustive_alist f i =
    (if i = 0 then None
     else
      case f empty of
        Some ts \<Rightarrow> Some ts
      | None \<Rightarrow>
          exhaustive_alist
            (\<lambda>a. Quickcheck_Exhaustive.exhaustive
              (\<lambda>k. Quickcheck_Exhaustive.exhaustive (\<lambda>v. f (update k v a)) (i - 1)) (i - 1))
            (i - 1))"

instance ..

end

instantiation alist :: (full_exhaustive, full_exhaustive) full_exhaustive
begin

fun full_exhaustive_alist ::
  "(('a, 'b) alist \<times> (unit \<Rightarrow> term) \<Rightarrow> (bool \<times> term list) option) \<Rightarrow> natural \<Rightarrow>
    (bool \<times> term list) option"
where
  "full_exhaustive_alist f i =
    (if i = 0 then None
     else
      case f valterm_empty of
        Some ts \<Rightarrow> Some ts
      | None \<Rightarrow>
          full_exhaustive_alist
            (\<lambda>a.
              Quickcheck_Exhaustive.full_exhaustive
                (\<lambda>k. Quickcheck_Exhaustive.full_exhaustive (\<lambda>v. f (valterm_update k v a)) (i - 1))
              (i - 1))
            (i - 1))"

instance ..

end


section \<open>alist is a BNF\<close>

lift_definition map :: "('a \<Rightarrow> 'b) \<Rightarrow> ('k, 'a) alist \<Rightarrow> ('k, 'b) alist"
  is "\<lambda>f xs. List.map (map_prod id f) xs" by simp

lift_definition set :: "('k, 'v) alist => 'v set"
  is "\<lambda>xs. snd ` List.set xs" .

lift_definition rel :: "('a \<Rightarrow> 'b \<Rightarrow> bool) \<Rightarrow> ('k, 'a) alist \<Rightarrow> ('k, 'b) alist \<Rightarrow> bool"
  is "\<lambda>R xs ys. list_all2 (rel_prod op = R) xs ys" .

bnf "('k, 'v) alist"
  map: map
  sets: set
  bd: natLeq
  wits: empty
  rel: rel
proof (unfold OO_Grp_alt)
  show "map id = id" by (rule ext, transfer) (simp add: prod.map_id0)
next
  fix f g
  show "map (g \<circ> f) = map g \<circ> map f"
    by (rule ext, transfer) (simp add: prod.map_comp)
next
  fix x f g
  assume "(\<And>z. z \<in> set x \<Longrightarrow> f z = g z)"
  then show "map f x = map g x" by transfer force
next
  fix f
  show "set \<circ> map f = op ` f \<circ> set"
    by (rule ext, transfer) (simp add: image_image)
next
  fix x
  show "ordLeq3 (card_of (set x)) natLeq"
    by transfer (auto simp: finite_iff_ordLess_natLeq[symmetric] intro: ordLess_imp_ordLeq)
next
  fix R S
  show "rel R OO rel S \<le> rel (R OO S)"
    by (rule predicate2I, transfer)
      (auto simp: list.rel_compp prod.rel_compp[of "op =", unfolded eq_OO])
next
  fix R
  show "rel R = (\<lambda>x y. \<exists>z. z \<in> {x. set x \<subseteq> {(x, y). R x y}} \<and> map fst z = x \<and> map snd z = y)"
   unfolding fun_eq_iff by transfer (fastforce simp: list.in_rel o_def intro:
     exI[of _ "List.map (\<lambda>p. ((fst p, fst (snd p)), (fst p, snd (snd p)))) z" for z]
     exI[of _ "List.map (\<lambda>p. (fst (fst p), snd (fst p), snd (snd p))) z" for z])
next
  fix z assume "z \<in> set empty"
  then show False by transfer simp
qed (simp_all add: natLeq_cinfinite natLeq_card_order)

hide_const valterm_empty valterm_update random_aux_alist

hide_fact (open) lookup_def empty_def update_def delete_def map_entry_def filter_def map_default_def
hide_const (open) impl_of lookup empty update delete map_entry filter map_default map set rel

end
