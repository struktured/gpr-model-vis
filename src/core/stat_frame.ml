open Core.Std

module Stat =
struct
  type t = [`Mean | `Variance] [@@deriving enum]
  let to_string = function
    | `Mean -> "Mean"
    | `Variance -> "Variance"
  let of_string : string -> t option = function
    | "Mean" -> Some `Mean
    | "Variance" -> Some `Variance
    | s -> None
  let domain = function
    | `Mean -> `Range (Float.neg_infinity, Float.infinity)
    | `Variance -> `Range (Float.neg_infinity, Float.infinity)
end

module Stat_frame = Data_frame.Enum.Make(Stat)
module With_inputs(F:Data_frame.S) : Data_frame.S with type t = [`Input of F.t |
                                                           `Stat of Stat.t] =
struct
  type t = [`Input of F.t | `Stat of Stat.t] 

  let all = Array.concat [(Array.map ~f:(fun t -> `Input t) F.all);
                            (Array.map ~f:(fun t -> `Stat t) Stat_frame.all)]

  let to_int : t -> int = function `Input t -> F.to_int t | `Stat s -> 
    Stat_frame.to_int s + Array.length Stat_frame.all

  let get t arr : 'a option =
    let i = to_int t in
    if i < Array.length arr then Some arr.(i) else None

  let to_string = function `Input t -> F.to_string t | `Stat s -> Stat_frame.to_string s

  let of_string t = match F.of_string t with Some f -> Some (`Input f) | None ->
  match Stat_frame.of_string t with Some s -> Some (`Stat s) | None -> None

  let domain = function 
    | `Input i -> F.domain i
    | `Stat s -> Stat_frame.domain s
  let min = function 
    | `Input i -> F.min i
    | `Stat s -> Stat_frame.min s
   let max = function 
    | `Input i -> F.max i
    | `Stat s -> Stat_frame.max s

   let of_int i =
     match F.of_int i with Some x -> Some (`Input x) | None -> match
         Stat_frame.of_int (Array.length Stat_frame.all - i) 
       with Some x -> Some (`Stat x) | None -> None
   let sub_array elems arr =
     Array.filteri ~f:(fun i _ -> List.exists ~f:(fun x -> of_int i = Some x) elems)
       arr
end

include Stat_frame



