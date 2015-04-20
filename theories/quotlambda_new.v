Require Import ssreflect ssrfun ssrbool ssrnat eqtype choice seq.
Require Import bigop fintype finfun finset generic_quotient perm.
Require Import tuple.
Require Import fingroup.
Require Import finmap.
Require Import finsfun.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Delimit Scope finperm_scope with fperm.
Local Open Scope finperm_scope.
Local Open Scope fset.

Definition atom := nat.

Section FinPermDef.

Record finPerm := FinPerm {
  perm_of :> finsfun (@id atom);
  _ : injectiveb_finsfun_id  perm_of
}.

Lemma finperm_inj (π : finPerm) : injective π.
Proof. by case:π => *; apply/injectiveb_finsfunP. Qed.

Lemma in_permsupp (π : finPerm) : {mono π : a / a \in finsupp π}.
Proof. 
move=> a; case: π => f /=.
move=> /andP [/finsfun_injective_inP f_inj_in /forallP f_stable].
by case: (finsfunP _ a) => [/negPf -> //|af]; apply: (f_stable (SeqSub af)).
Qed.

Lemma perm_stable (π : finPerm) (S : {fset atom}) :
  finsupp π \fsubset S -> forall (a : atom), a \in S -> π a \in S. 
Proof.
move=> /fsubsetP S_surfinsupp a; case:finsfunP; first by []. 
by move => a_supp aS; apply/S_surfinsupp/(monoW (@in_permsupp _)).
Qed.

Definition eq_finPerm (π π' : finPerm) :=
    [forall a: (finsupp π :|: finsupp π'), π (val a) == π' (val a) :> nat].

Lemma eq1_finPermP (π π' : finPerm) : reflect (π =1 π') (eq_finPerm π π').
Proof.
apply: (iffP idP); last first.
  move => π_eq_π'. apply/forallP => *. by apply/eqP/π_eq_π'.
move => /forallP π_eq_π' a. 
have [aππ'|aNππ'] := boolP (a \in (finsupp π :|: finsupp π')).
  by apply/eqP/(π_eq_π' (SeqSub aππ')).
move:aNππ'; rewrite in_fsetU negb_or => /andP [aNπ aNπ'].
by rewrite !finsfun_dflt.
Qed.

Lemma eq_finPermP (π π' : finPerm) : π =1 π' <-> π = π'.
Proof.
split; last by move ->.
case: π; case: π' => f f_inj g g_inj g_eq1_f.
suff g_eq_f : g = f.
  move: g_eq_f f_inj g_inj g_eq1_f-> => f_inj g_inj _. congr FinPerm. 
  exact: bool_irrelevance.
by apply eq_finsfunP.
Qed.

Lemma eq_finPerm_is_equiv : equiv_class_of eq_finPerm.
Proof.
split=> [p|p q|q p r].
  rewrite /eq_finPerm. by apply/forallP.
  rewrite /eq_finPerm. apply/forallP/forallP => H; rewrite fsetUC => x; by rewrite eq_sym. 
move=> /eq1_finPermP pq /eq1_finPermP qr.
by apply/eq1_finPermP => n; rewrite pq qr.
Qed.


End FinPermDef.

Section PermFinPerm.

Definition ffun_of_finPerm (π : finPerm) (S : {fset atom}) 
           (supp_incl_S : finsupp π \fsubset S) := 
  [ffun x:S => SeqSub (perm_stable supp_incl_S (ssvalP x))].

Fact perm_of_finPerm_subproof (π : finPerm) (S : {fset atom}) 
      (supp_incl_S : finsupp π \fsubset S) : injectiveb (ffun_of_finPerm supp_incl_S). 
Proof.
apply/injectiveP => a b; rewrite !ffunE; move/(congr1 val) => πa_eq_πb. 
by apply/val_inj/(finperm_inj πa_eq_πb).
Qed.

Definition perm_of_finPerm (π : finPerm) (S : {fset atom}) 
           (supp_incl_S : finsupp π \fsubset S) := 
  Perm (perm_of_finPerm_subproof supp_incl_S).

Definition can_perm_of_finPerm (π : finPerm) := 
  perm_of_finPerm (fsubsetAA (finsupp π)).

Lemma perm_of_finPermE (π : finPerm) (S : {fset atom}) 
      (supp_incl_S : finsupp π \fsubset S) :
  forall a : S, perm_of_finPerm supp_incl_S a = SeqSub (perm_stable supp_incl_S (ssvalP a)).
Proof. move => a. by rewrite/perm_of_finPerm -pvalE /ffun_of_finPerm /= ffunE. Qed.

(* Probablement inutile 
Let finsfun_of_perm (S : {fset atom}) (p : {perm S}) :=
finsfun_of_fun (@id atom) (fun_of_ffun (@id atom) [ffun x:S => val (p x)]) S. 

Lemma finsfun_of_permE (S : {fset atom}) (p : {perm S}) :
  finsfun_of_perm p =1 fun_of_ffun (@id atom) [ffun x:S => val (p x)].
Proof.
move=> a; rewrite finsfun_of_funE // => {a} a.
by apply: contraNT => /out_fun_of_ffun ->.
Qed.

Lemma finsfun_of_perm_incl (S : {fset atom}) (p : {perm S}) :
  finsupp (finsfun_of_perm p) \fsubset S.
Proof.
apply/fsubsetP => a. 
rewrite mem_finsupp finsfun_of_permE. by apply/contraR/out_fun_of_ffun.
Qed.

Fact finPerm_of_perm_subproof (S : {fset atom}) (p : {perm S}) : 
  injectiveb_finsfun_id (finsfun_of_perm p).
Proof. 
apply/injectiveb_finsfunP/injective_finsfunP; exists S.
  by apply/fsubsetP => a /in_FSetE [].
split.
  move => a b aS bS /=; rewrite !finsfun_of_permE //=. 
  by rewrite !in_fun_of_ffun !ffunE /= => /val_inj /(@perm_inj _ p) [].
  (* :BUG: Why do we need to provide p ? Check with 8.5 *)
by move=> [a aS]; rewrite finsfun_of_permE in_fun_of_ffun ffunE (valP p.[aS])%fmap.
Qed.

Definition finPerm_of_perm (S : {fset atom}) (p : {perm S}) :=
  FinPerm (finPerm_of_perm_subproof p).

Lemma finPerm_of_perm_incl (S : {fset atom}) (p : {perm S}) :
  finsupp (finPerm_of_perm p) \fsubset S.
Proof.
apply/fsubsetP => a. 
rewrite mem_finsupp finsfun_of_permE. by apply/contraR/out_fun_of_ffun.
Qed.

Lemma finPerm_of_permE (S : {fset atom}) (p : {perm S}) (a : atom) (aS : a \in S) :
    (finPerm_of_perm p) a = val (p (SeqSub aS)).
Proof. 
rewrite finsfun_of_funE; first by rewrite in_fun_of_ffun ffunE. 
move => b. apply contraR. exact: out_fun_of_ffun.
Qed.

Lemma support_finPerm_of_permE (S : {fset atom}) (p : {perm S}) :
  (forall a : S, p a != a) -> finsupp (finPerm_of_perm p) = S.
Proof.
move => H. apply/fsetP => a. rewrite mem_finsupp. apply/idP/idP; last first.
  move => aS. rewrite finPerm_of_permE. exact: H.
rewrite -mem_finsupp. exact: fsubsetP (finPerm_of_perm_incl p) a.
Qed.

End PermFinPerm.

*)

Section FinPermSpec.

Lemma finPerm_can (π : finPerm) (a : atom) (aπ : a\in finsupp π) :
  π a = (val (can_perm_of_finPerm π (SeqSub aπ))).
Proof.
have t : π a = val (SeqSub (perm_stable (fsubsetAA (finsupp π)) aπ)) by []. 
rewrite t. congr val.
by rewrite perm_of_finPermE. 
Qed.

CoInductive finPerm_spec (π : finPerm) (a : atom) : atom -> bool -> Type :=
  | FinPermOut : a \notin finsupp π -> finPerm_spec π a a false
  | FinPermIn  (aπ : a \in finsupp π) : 
      finPerm_spec π a (val (can_perm_of_finPerm π (SeqSub aπ))) true.

Lemma finPermP (π : finPerm) (a : atom) : finPerm_spec π a (π a) (a \in finsupp π).
Proof.
case:finsfunP; first by exact: FinPermOut.
move => aπ. suff: π a = (val (can_perm_of_finPerm π (SeqSub aπ))).
  by move ->; apply: FinPermIn.
exact: finPerm_can.
Qed.

End FinPermSpec.

Section FinPermInvDef.

Variable (π : finPerm).

Let p := can_perm_of_finPerm π.
Let inv_p_ffun := [ffun a : finsupp π => val ( p^-1%g a)].

Fact can_p_subproof : [forall a : finsupp π ,  inv_p_ffun a != val a].
Proof.
apply/forallP => a. rewrite ffunE val_eqE.
rewrite (can2_eq (permKV p) (permK p)).
rewrite perm_of_finPermE -val_eqE eq_sym -mem_finsupp. exact: ssvalP.
Qed.

Definition finsfun_invp_subproof := @finsfun_of_can_ffun _ _ (@id atom) _ _ can_p_subproof.

Fact injective_finsfun_subproof : injectiveb_finsfun_id finsfun_invp_subproof.
Proof.
apply/andP. split; last first.
  apply/forallP => a. rewrite !finsfun_of_can_ffunE; first by apply: valP.
  move => aπ /=. rewrite ffunE. exact: valP.
apply/injectiveP => a b. rewrite !ffunE !finsfun_of_can_ffunE; rewrite ?ssvalP //=.
move => bπ aπ. rewrite !ffunE => pa_eq_pb.
suff: {| ssval := ssval a; ssvalP := aπ |} = {| ssval := ssval b; ssvalP := bπ |}.
  by move/(congr1 val) => /=; apply/val_inj. 
apply/eqP. rewrite -(inj_eq (@perm_inj _ (perm_inv (can_perm_of_finPerm π)))).
rewrite -val_eqE. by apply/eqP.
Qed.

Definition finperm_inv := 
  FinPerm injective_finsfun_subproof.

Lemma finperm_one_subproof : injectiveb_finsfun_id (@finsfun_one nat_KeyType).
Proof. by apply/injectiveb_finsfunP/inj_finsfun_one. Qed.

Definition finperm_one := FinPerm finperm_one_subproof.

End FinPermInvDef. 

Section FinPermMulDef.

Lemma finperm_mul_subproof (π π' : finPerm) :
  injectiveb_finsfun_id (@finsfun_comp nat_KeyType π π').
Proof. apply/injectiveb_finsfunP/inj_finsfun_comp; by apply finperm_inj. Qed.

Definition finperm_mul (π π' : finPerm) :=
  FinPerm (finperm_mul_subproof π π').

Notation "1" := finperm_one.
Notation "π * π'" := (finperm_mul π π').
Notation "π ^-1" := (finperm_inv π) : finperm_scope.
Notation "π ~" := (can_perm_of_finPerm π) 
  (at level 0) : finperm_scope.  

Section FinPermTheory.

Implicit Types (π : finPerm) (a : atom).

Lemma can_inv π : π^-1~ = π~^-1%g.
Proof.
apply permP => a. rewrite perm_of_finPermE.
apply val_inj => /=. rewrite finsfun_of_can_ffunE; first by apply: valP.
move => aπ /=. rewrite ffunE.  congr ssval. 
suff : {| ssval := ssval a; ssvalP := aπ |} = a by move ->.
by apply val_inj.
Qed.

Lemma finperm_invK : involutive finperm_inv.
Proof.
move => π. apply/eq_finPermP/eq1_finPermP/forallP. 
rewrite fsetUid => a. rewrite !finPerm_can; do ?apply: valP.
move => aπ ainvinvπ. rewrite val_eqE can_inv can_inv invgK.
suff : ainvinvπ = aπ by move ->.
exact: bool_irrelevance.
Qed.

Lemma myvalK  (S : {fset atom}) (a : S) aS :
  {| ssval := val a;
     ssvalP := aS |} = a.
Proof. by apply val_inj. Qed.

(* le lemme myvalK doit déjà exister, mais je l'ai pas trouvé *)

Lemma permK π : cancel π π^-1.
Proof.
move => a. case: (finPermP π a) => [aNπ | aπ].
  by rewrite finsfun_dflt.
rewrite finPerm_can; first by apply: valP.
move => πaπ. by rewrite myvalK can_inv -permM mulgV perm1.
Qed.

Lemma permVK π : cancel π^-1 π.
Proof. by move=> a; rewrite -{1}[π]finperm_invK permK. Qed.

Lemma finperm_invP : left_inverse finperm_one finperm_inv finperm_mul.
Proof.
move => π. apply/eq_finPermP => a. 
by rewrite finsfunM /= permK finsfun1. 
Qed.

Lemma finperm_invVP : right_inverse finperm_one finperm_inv finperm_mul.
Proof. move => π. by rewrite -(finperm_invP π^-1) finperm_invK. Qed.

End FinPermTheory.

Section Transpositions.

Implicit Types (a b c : atom).

Definition tffun a b  := [ffun x : [fset a;b] => if val x == a then b else a].

Lemma tfinsfun_subproof a b (a_neq_b : a != b) : 
  [forall k, tffun a b k != val k].
Proof.
apply/forallP => k. move: (valP k). 
rewrite in_fset2 => /orP. case =>  [k_eq_a | k_eq_b]. 
  by rewrite ffunE k_eq_a (eqP k_eq_a) eq_sym. 
by rewrite ffunE (eqP k_eq_b) [b==a]eq_sym (negbTE a_neq_b).
Qed.

Definition tfinsfun a b (a_neq_b : a != b) := 
  @finsfun_of_can_ffun _ _ (@id atom) _ _ (tfinsfun_subproof a_neq_b).

Lemma inv_tfinsfun a b (a_neq_b : a != b) :
  involutive (tfinsfun a_neq_b).
Proof.
move => c. case : (finsfunP _ c); first by move => *; rewrite finsfun_dflt.
rewrite in_fset2 => /orP. case => /eqP ->.
rewrite !finsfun_of_can_ffunE.
  - exact: set21.
  - move => *. by rewrite ffunE eq_refl set22. 
  - exact: set21.
  - move => *. by rewrite !ffunE /= ffunE /= eq_refl eq_sym (negbTE a_neq_b).
rewrite !finsfun_of_can_ffunE.
  - exact: set22.
  - move => *. by rewrite ffunE /= eq_sym (negbTE a_neq_b) set21. 
  - exact: set22.
  - move => *. by rewrite !ffunE /= ffunE /= [b==a]eq_sym (negbTE a_neq_b) eq_refl.
Qed.

(* à factoriser *)

Lemma inj_tfinsfun a b (a_neq_b : a != b) : 
  injectiveb_finsfun_id (tfinsfun a_neq_b).
Proof. by apply/injectiveb_finsfunP/inv_inj/inv_tfinsfun. Qed.

Definition tfinperm a b (a_neq_b : a != b) :=
  FinPerm (inj_tfinsfun a_neq_b).

CoInductive tfinperm_spec a b c : atom -> Type :=
  | TFinpermFirst : c = a -> tfinperm_spec a b c b
  | TFinpermSecond : c = b -> tfinperm_spec a b c a
  | TFinpermNone : (c != a) && (c != b) -> tfinperm_spec a b c c.

Lemma tfinpermP a b c (a_neq_b : a != b) : 
  tfinperm_spec a b c (tfinperm a_neq_b c).
Proof.
case: finsfunP; rewrite in_fset2. 
  by rewrite negb_or; exact: TFinpermNone.
move => cab; rewrite finsfun_of_can_ffunE.
  case: (orP cab) => /eqP ->. exact: set21. exact: set22.
move => *. rewrite ffunE /=.
case ca : (c == a); first by apply/TFinpermFirst/(eqP ca).
move: ca cab -> => /eqP ->. by apply TFinpermSecond.
Qed.

End Transpositions.




Section NominalDef.

Implicit Types (π : finPerm).

Record perm_setoid_mixin (X : Type) (R : X -> X -> Prop) := PermSetoidMixin {
  act : finPerm -> X -> X;
  _ : forall x, R ((act 1) x) x;
  _ : forall π π' x, R (act (π * π') x) (act π (act π' x));
  _ : forall x y π, R x y -> R (act π x) (act π y)
}.

Record nominal_mixin (X : choiceType) := NominalMixin {
  perm_setoid_of : @perm_setoid_mixin X (@eq X);
  support : X -> {fset atom}; 
  _ : forall π x, 
        (forall a : atom, a \in support x -> π a = a) -> (act perm_setoid_of π x) = x
}.

                                    
End NominalDef.

Section NominalAtoms.

Implicit Types (π : finPerm) (a : atom).

Local Notation atomact := (fun (π : finPerm) (a : atom) => π a).

Lemma atomact1 : forall (a : atom), atomact 1 a = a.
Proof. by move => a /=; rewrite finsfun1. Qed.

Lemma atomactM : forall π π' a, atomact (π * π') a = atomact π (atomact π' a).
Proof. by move => π π' a /=; rewrite finsfunM. Qed.

Lemma atomactproper : forall x y π, x = y -> (atomact π x) = (atomact π y).
Proof. by move => x y π ->. Qed.

Definition atom_nominal_setoid_mixin := 
  @PermSetoidMixin atom (@eq atom) atomact atomact1 atomactM atomactproper.   

Lemma atomact_id π a :
     (forall b, b \in fset1 a -> atomact π b = b) -> atomact π a = a.
Proof. apply. by rewrite in_fset1. Qed.

Definition atom_nominal_mixin :=
  @NominalMixin nat_choiceType atom_nominal_setoid_mixin _ atomact_id.

End NominalAtoms.

Section NominalTheory.

Variables (T : choiceType) (X : nominal_mixin T). 
Implicit Types (π : finPerm) (x : T).

Local Notation act π := (act (perm_setoid_of X) π ).
Local Notation support := (support X).

Lemma act1 : act 1 =1 id.
Proof. by case: X; case. Qed.

Lemma actM (π π' : finPerm) x : act (π * π') x = act π (act π' x).
Proof. by case: X; case. Qed.

Lemma act_id π x : (forall a : atom, a \in support x -> π a = a) 
                   -> (act π x) = x.
Proof. case: X => ps supp. exact. Qed.

Lemma actK π : cancel (act π) (act π^-1).
Proof. by move => x; rewrite -actM (finperm_invP π) act1. Qed.

Lemma actVK π : cancel (act π^-1) (act π).
Proof. by move => x; rewrite -actM (finperm_invVP π) act1. Qed.