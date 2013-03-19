(*
Copyright (c) 2013, Simon Cruanes
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.  Redistributions in binary
form must reproduce the above copyright notice, this list of conditions and the
following disclaimer in the documentation and/or other materials provided with
the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

(** {1 Futures for concurrency} *)

type 'a t
  (** A future value of type 'a *)

exception SendTwice
  (** Exception raised when a future is evaluated several time *)

(** {2 Thread pool} *)
module Pool : sig
  type t
    (** A pool of threads *)

  val create : size:int -> t
    (** Create a pool with the given number of threads. *)

  val schedule : t -> (unit -> unit) -> unit
    (** Schedule a function to run in the pool *)

  val finish : t -> unit
    (** Kill threads in the pool *)
end

val default_pool : Pool.t
  (** Pool of threads that is used by default *)

(** {2 Basic low-level Future functions} *)

val make : unit -> 'a t
  (** Create a future, representing a value that is not known yet. *)

val get : 'a t -> 'a
  (** Blocking get: wait for the future to be evaluated, and get the value,
      or the exception that failed the future is returned *)

val send : 'a t -> 'a -> unit
  (** Send a result to the future. Will raise SendTwice if [send] has
      already been called on this future before *)

val fail : 'a t -> exn -> unit
  (** Fail the future by raising an exception inside it *)

val is_done : 'a t -> bool
  (** Is the future evaluated (success/failure)? *)

(** {2 Combinators *)

val flatMap : ?pool:Pool.t -> ('a -> 'b t) -> 'a t -> 'b t
  (** Monadic combination of futures *)

(** {2 Future constructors} *)

val return : 'a -> 'a t
  (** Future that is already computed *)

val spawn : ?pool:Pool.t -> (unit -> 'a) -> 'a t
  (** Spawn a thread that wraps the given computation *)

val spawn_process : ?pool:Pool.t -> ?stdin:string -> cmd:string ->
                    (int * string * string) t
  (** Spawn a sub-process with the given command [cmd] (and possibly input);
      returns a future containing (returncode, stdout, stderr) *)

module Infix : sig
  val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
end