exception Duplicate_key 
exception Missing_key
   

class ['a] container (indexer : 'a -> 'b) = object(self)
    
  val storage = ref []

  method add key =
    if not (self#mem key) then
      storage := (indexer key, key) :: !storage
			 
  method mem key = List.mem_assoc (indexer key) !storage
      
  method isEmpty = !storage == []

  method size = List.length !storage

  method choose = snd (List.hd !storage)

  method remove chaff =
    if not (self#mem chaff) then raise Missing_key;
    storage := List.remove_assoc (indexer chaff) !storage

  method iter action =
    List.iter (fun (_, key) -> action key) !storage
end
