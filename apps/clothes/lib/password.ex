defmodule Clothes.Password do
  import Bcrypt

  def hash(password), do: hash_pwd_salt(password)
end
