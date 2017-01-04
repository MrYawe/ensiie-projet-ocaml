(**
  The type rquadtree and its operations are designed to represent a
  region quadtree.

  A region quadtree is an adaptation of a binary tree used to represent a
  black and white image.

  @author Yannis Weishaupt
 *)

open Point;;
open Rectangle;;

(**
  The sum type representing the possible colors of a empty rquadtree.
 *)
type colors = White | Black ;;

(**
  The sum type representing the region quadtree with:
  {ul {- [Plain] the empty rquadtree that will be drawn in black or white}
      {- [RQ] a node of the rquadtree}}

  Each [RQ] contains 4 children of {!type:Rquadtree.rquadtree}.
 *)
type rquadtree =
    Plain of colors
  | RQ of rquadtree * rquadtree * rquadtree * rquadtree;;

(**
  Exception raised when a given encoded rquadtree is inconsistent.
 *)
exception InconsistentEncoding;;


(**
  Invert the color of each [Plain] in the given rquadtree.
 *)
let rec invert = function
  | Plain White -> Plain Black
  | Plain Black -> Plain White
  | RQ (q1, q2, q3, q4) -> RQ (invert q1, invert q2, invert q3, invert q4);;

(**
  Return the rquadtree result of the intersection of two given rquadtree.

  If one pixel of the intersection rquadtree is black then this pixel is black
  in the first and the second given rquadtree.
 *)
let rec intersection rquadtree1 rquadtree2 =
  match (rquadtree1, rquadtree2) with
    | (RQ (q11, q12, q13, q14), RQ (q21, q22, q23, q24)) ->
        RQ (intersection q11 q21, intersection q12 q22, intersection q13 q23,
          intersection q14 q24)
    | (Plain Black, RQ (q1, q2, q3, q4)) | (RQ (q1, q2, q3, q4), Plain Black) ->
      RQ ((intersection (Plain Black) q1), (intersection (Plain Black) q3),
        (intersection (Plain Black) q3), (intersection (Plain Black) q4))
    | (Plain Black, Plain Black) -> Plain Black
    | _ -> Plain White;;

(**
  Return the rquadtree result of the union of two given rquadtree.

  If one pixel of the union rquadtree is black then this pixel is black
  in the first or the second given rquadtree.
 *)
let rec union rquadtree1 rquadtree2 =
  match (rquadtree1, rquadtree2) with
    | (RQ (q11, q12, q13, q14), RQ (q21, q22, q23, q24)) ->
      let res = RQ (union q11 q21, union q12 q22, union q13 q23, union q14 q24)
      in (match res with
        | RQ (Plain Black, Plain Black, Plain Black, Plain Black) -> Plain Black
        | _ -> res)
    | (Plain White, RQ (q1, q2, q3, q4)) | (RQ (q1, q2, q3, q4), Plain White) ->
      RQ ((union (Plain White) q1), (union (Plain White) q3),
        (union (Plain White) q3), (union (Plain White) q4))
    | (Plain White, Plain White) -> Plain White
    | _ -> Plain Black;;

(**
  Perform a vertical symmetry on the given rquadtree and return
  the resulting rquadtree.

  The axis of symmetry is the right border of the rquadtree.
 *)
let rec vertical_symmetry = function
  | Plain c -> Plain c
  | RQ (q1, q2, q3, q4) ->
    RQ (vertical_symmetry q2, vertical_symmetry q1,
      vertical_symmetry q4, vertical_symmetry q3);;

(**
  Perform a horizontal symmetry on the given rquadtree and return
  the resulting rquadtree.

  The axis of symmetry is the bottom border of the rquadtree.
 *)
let rec horizontal_symmetry = function
  | Plain c -> Plain c
  | RQ (q1, q2, q3, q4) ->
    RQ (vertical_symmetry q3, vertical_symmetry q4,
      vertical_symmetry q1, vertical_symmetry q2);;

(**
  Return the binary encoding of the given rquadtree as list of [O] or [1].
 *)
let code rquadtree =
  let rec code_step acc = function
    | Plain White -> 1::0::acc
    | Plain Black -> 1::1::acc
    | RQ (q1, q2, q3, q4) ->
      0::(code_step (code_step (code_step (code_step acc q4) q3) q2) q1)
  in code_step [] rquadtree;;

(**
  Decode the given rquadtree encoding and return the resulting rquadtree.

  Raise [InconsistentEncoding] if the given encoding is inconsistent.
 *)
let decode l =
  let rec decode_step = function
    | 1::0::l -> Plain White, l
    | 1::1::l -> Plain Black, l
    | 0::l ->
      let q1, l = decode_step l in
      let q2, l = decode_step l in
      let q3, l = decode_step l in
      let q4, l = decode_step l in
        RQ (q1, q2, q3, q4), l
    | _ -> raise InconsistentEncoding
  in let rqt, _ = decode_step l in rqt;;

(**
  The default graphical origin used by draw functions of this module.

  Its value is [{x=0; y=0}].
 *)
let base_g_origin = {x=0; y=0};;

(**
  Draw the given rquadtree with the graphic module of OCaml.

  TODO
  Raise [InconsistentRquadtree] if the given rquadtree is inconsistent.

  @param scale Optional scaling parameter. For example if [scale = 2] a
  rquadtree's surface of height [10] will be drawn with a height
  of [20] pixels. Default is [1].
  TODO
  @param g_origin Optional parameter representing the graphical origin of the
  coordinate system where the rquadtree is drawn. Default is
  {!val:Rquadtree.base_g_origin}.
 *)
let draw_rquadtree ?(scale=1) base_size rquadtree =
  let rec aux scale rect = function
    | Plain White ->
      draw_plain_rectangle ~scale:scale rect Graphics.white;
      draw_rectangle ~scale:scale rect
    | Plain Black ->
      draw_plain_rectangle ~scale:scale rect Graphics.black;
      draw_rectangle ~scale:scale rect
    | RQ (q1, q2, q3, q4) ->
      let c = center rect in
        aux scale {top=rect.top; right=c.x; bottom=c.y; left=rect.left} q1;
        aux scale {top=rect.top; right=rect.right; bottom=c.y; left=c.x} q2;
        aux scale {top=c.y; right=c.x; bottom=rect.bottom; left=rect.left} q3;
        aux scale {top=c.y; right=rect.right; bottom=rect.bottom; left=c.x} q4;
  in aux scale {top=base_size; right=base_size; bottom=0; left=0} rquadtree;;
