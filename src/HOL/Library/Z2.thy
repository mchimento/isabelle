(*  Title:      HOL/Library/Z2.thy
    Author:     Brian Huffman
*)

section \<open>The Field of Integers mod 2\<close>

theory Z2
imports Main "HOL-Library.Bit_Operations"
begin

text \<open>
  Note that in most cases \<^typ>\<open>bool\<close> is appropriate hen a binary type is needed; the
  type provided here, for historical reasons named \<^text>\<open>bit\<close>, is only needed if proper
  field operations are required.
\<close>

subsection \<open>Bits as a datatype\<close>

typedef bit = "UNIV :: bool set"
  morphisms set Bit ..

instantiation bit :: "{zero, one}"
begin

definition zero_bit_def: "0 = Bit False"

definition one_bit_def: "1 = Bit True"

instance ..

end

old_rep_datatype "0::bit" "1::bit"
proof -
  fix P :: "bit \<Rightarrow> bool"
  fix x :: bit
  assume "P 0" and "P 1"
  then have "\<forall>b. P (Bit b)"
    unfolding zero_bit_def one_bit_def
    by (simp add: all_bool_eq)
  then show "P x"
    by (induct x) simp
next
  show "(0::bit) \<noteq> (1::bit)"
    unfolding zero_bit_def one_bit_def
    by (simp add: Bit_inject)
qed

lemma Bit_set_eq [simp]: "Bit (set b) = b"
  by (fact set_inverse)

lemma set_Bit_eq [simp]: "set (Bit P) = P"
  by (rule Bit_inverse) rule

context
begin

qualified lemma bit_eq_iff: "x = y \<longleftrightarrow> (set x \<longleftrightarrow> set y)"
  by (auto simp add: set_inject)

end

lemma Bit_inject [simp]: "Bit P = Bit Q \<longleftrightarrow> (P \<longleftrightarrow> Q)"
  by (auto simp add: Bit_inject)

lemma set [iff]:
  "\<not> set 0"
  "set 1"
  by (simp_all add: zero_bit_def one_bit_def Bit_inverse)

lemma [code]:
  "set 0 \<longleftrightarrow> False"
  "set 1 \<longleftrightarrow> True"
  by simp_all

lemma set_iff: "set b \<longleftrightarrow> b = 1"
  by (cases b) simp_all

lemma bit_eq_iff_set:
  "b = 0 \<longleftrightarrow> \<not> set b"
  "b = 1 \<longleftrightarrow> set b"
  by (simp_all add: Z2.bit_eq_iff)

lemma Bit [simp, code]:
  "Bit False = 0"
  "Bit True = 1"
  by (simp_all add: zero_bit_def one_bit_def)

lemma bit_not_0_iff [iff]: "x \<noteq> 0 \<longleftrightarrow> x = 1" for x :: bit
  by (simp add: Z2.bit_eq_iff)

lemma bit_not_1_iff [iff]: "x \<noteq> 1 \<longleftrightarrow> x = 0" for x :: bit
  by (simp add: Z2.bit_eq_iff)

lemma [code]:
  "HOL.equal 0 b \<longleftrightarrow> \<not> set b"
  "HOL.equal 1 b \<longleftrightarrow> set b"
  by (simp_all add: equal set_iff)


subsection \<open>Type \<^typ>\<open>bit\<close> forms a field\<close>

instantiation bit :: field
begin

definition plus_bit_def: "x + y = case_bit y (case_bit 1 0 y) x"

definition times_bit_def: "x * y = case_bit 0 y x"

definition uminus_bit_def [simp]: "- x = x" for x :: bit

definition minus_bit_def [simp]: "x - y = x + y" for x y :: bit

definition inverse_bit_def [simp]: "inverse x = x" for x :: bit

definition divide_bit_def [simp]: "x div y = x * y" for x y :: bit

lemmas field_bit_defs =
  plus_bit_def times_bit_def minus_bit_def uminus_bit_def
  divide_bit_def inverse_bit_def

instance
  by standard (auto simp: plus_bit_def times_bit_def split: bit.split)

end

lemma bit_add_self: "x + x = 0" for x :: bit
  unfolding plus_bit_def by (simp split: bit.split)

lemma bit_mult_eq_1_iff [simp]: "x * y = 1 \<longleftrightarrow> x = 1 \<and> y = 1" for x y :: bit
  unfolding times_bit_def by (simp split: bit.split)

text \<open>Not sure whether the next two should be simp rules.\<close>

lemma bit_add_eq_0_iff: "x + y = 0 \<longleftrightarrow> x = y" for x y :: bit
  unfolding plus_bit_def by (simp split: bit.split)

lemma bit_add_eq_1_iff: "x + y = 1 \<longleftrightarrow> x \<noteq> y" for x y :: bit
  unfolding plus_bit_def by (simp split: bit.split)


subsection \<open>Numerals at type \<^typ>\<open>bit\<close>\<close>

text \<open>All numerals reduce to either 0 or 1.\<close>

lemma bit_minus1 [simp]: "- 1 = (1 :: bit)"
  by (simp only: uminus_bit_def)

lemma bit_neg_numeral [simp]: "(- numeral w :: bit) = numeral w"
  by (simp only: uminus_bit_def)

lemma bit_numeral_even [simp]: "numeral (Num.Bit0 w) = (0 :: bit)"
  by (simp only: numeral_Bit0 bit_add_self)

lemma bit_numeral_odd [simp]: "numeral (Num.Bit1 w) = (1 :: bit)"
  by (simp only: numeral_Bit1 bit_add_self add_0_left)


subsection \<open>Conversion from \<^typ>\<open>bit\<close>\<close>

context zero_neq_one
begin

definition of_bit :: "bit \<Rightarrow> 'a"
  where "of_bit b = case_bit 0 1 b"

lemma of_bit_eq [simp, code]:
  "of_bit 0 = 0"
  "of_bit 1 = 1"
  by (simp_all add: of_bit_def)

lemma of_bit_eq_iff: "of_bit x = of_bit y \<longleftrightarrow> x = y"
  by (cases x) (cases y; simp)+

end

lemma (in semiring_1) of_nat_of_bit_eq: "of_nat (of_bit b) = of_bit b"
  by (cases b) simp_all

lemma (in ring_1) of_int_of_bit_eq: "of_int (of_bit b) = of_bit b"
  by (cases b) simp_all


subsection \<open>Bit structure\<close>

instantiation bit :: semidom_modulo
begin

definition modulo_bit :: \<open>bit \<Rightarrow> bit \<Rightarrow> bit\<close>
  where [simp]: \<open>a mod b = a * of_bool (b = 0)\<close> for a b :: bit

instance
  by standard simp

end

instantiation bit :: semiring_bits
begin

definition bit_bit :: \<open>bit \<Rightarrow> nat \<Rightarrow> bool\<close>
  where [simp]: \<open>bit_bit b n \<longleftrightarrow> b = 1 \<and> n = 0\<close>

instance
  apply standard
                apply (auto simp add: power_0_left power_add set_iff)
   apply (metis bit_not_1_iff of_bool_eq(2))
  done

end

instantiation bit :: semiring_bit_shifts
begin

definition push_bit_bit :: \<open>nat \<Rightarrow> bit \<Rightarrow> bit\<close>
  where \<open>push_bit n b = (if n = 0 then b else 0)\<close> for b :: bit

definition drop_bit_bit :: \<open>nat \<Rightarrow> bit \<Rightarrow> bit\<close>
  where \<open>drop_bit n b = (if n = 0 then b else 0)\<close> for b :: bit

definition take_bit_bit :: \<open>nat \<Rightarrow> bit \<Rightarrow> bit\<close>
  where \<open>take_bit n b = (if n = 0 then 0 else b)\<close> for b :: bit

instance
  by standard (simp_all add: push_bit_bit_def drop_bit_bit_def take_bit_bit_def)

end

instantiation bit :: ring_bit_operations
begin

definition not_bit :: \<open>bit \<Rightarrow> bit\<close>
  where \<open>NOT b = of_bool (even b)\<close> for b :: bit

definition and_bit :: \<open>bit \<Rightarrow> bit \<Rightarrow> bit\<close>
  where \<open>b AND c = of_bool (odd b \<and> odd c)\<close> for b c :: bit

definition or_bit :: \<open>bit \<Rightarrow> bit \<Rightarrow> bit\<close>
  where \<open>b OR c = of_bool (odd b \<or> odd c)\<close> for b c :: bit

definition xor_bit :: \<open>bit \<Rightarrow> bit \<Rightarrow> bit\<close>
  where \<open>b XOR c = of_bool (odd b \<noteq> odd c)\<close> for b c :: bit

instance
  by standard (auto simp add: and_bit_def or_bit_def xor_bit_def not_bit_def add_eq_0_iff)

end

lemma add_bit_eq_xor:
  \<open>(+) = ((XOR) :: bit \<Rightarrow> _)\<close>
  by (auto simp add: fun_eq_iff plus_bit_def xor_bit_def)

lemma mult_bit_eq_and:
  \<open>(*) = ((AND) :: bit \<Rightarrow> _)\<close>
  by (simp add: fun_eq_iff times_bit_def and_bit_def split: bit.split)

lemma bit_NOT_eq_1_iff [simp]: "NOT b = 1 \<longleftrightarrow> b = 0"
  for b :: bit
  by (cases b) simp_all

lemma bit_AND_eq_1_iff [simp]: "a AND b = 1 \<longleftrightarrow> a = 1 \<and> b = 1"
  for a b :: bit
  by (cases a; cases b) simp_all


hide_const (open) set

end
