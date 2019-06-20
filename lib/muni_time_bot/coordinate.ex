defmodule MuniTimeBot.Coordinate do
  @moduledoc """
  Encapsulates a coordinate on the globe.

  Struct keys:
  - `latitude`: latitude in degree
  - `longitude`: longitude in degree
  """

  # From WGS84 Datum
  @earth_radius_m 6_371_008.8

  @enforce_keys ~w(latitude longitude)a
  defstruct @enforce_keys

  @type t :: %__MODULE__{latitude: float(), longitude: float()}

  defmacro is_degree(degree) do
    quote do
      is_float(unquote(degree)) and unquote(degree) >= -180.0 and unquote(degree) <= 180.0
    end
  end

  @spec new(float(), float()) :: {:ok, t()} | :error

  def new(latitude, longitude) when is_degree(latitude) and is_degree(longitude) do
    {:ok, %__MODULE__{latitude: latitude, longitude: longitude}}
  end

  def new(_, _) do
    :error
  end

  @doc """
  Calculate distance in metres between 2 coordinates using the haversine formula.

  From http://www.movable-type.co.uk/scripts/latlong.html
  """
  def distance(%__MODULE__{latitude: lat1, longitude: lon1}, %__MODULE__{
        latitude: lat2,
        longitude: lon2
      }) do
    half_dlat = (lat2 - lat1) / 2
    half_dlon = (lon2 - lon1) / 2
    lat_sin = half_dlat |> deg_to_rad() |> :math.sin()
    lon_sin = half_dlon |> deg_to_rad() |> :math.sin()

    lat1_rad = deg_to_rad(lat1)
    lat2_rad = deg_to_rad(lat2)

    a = lat_sin * lat_sin + lon_sin * lon_sin * :math.cos(lat1_rad) * :math.cos(lat2_rad)
    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))
    @earth_radius_m * c
  end

  defp deg_to_rad(degree) when is_degree(degree) do
    degree * :math.pi() / 180.0
  end
end
