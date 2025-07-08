const signupProvider = async (req, res) => {
  try {
    const {
      name,
      email,
      password,
      phoneNumber,
      businessName,
      businessAddress,
      serviceOffered,
      location,
    } = req.body;

    // Validate required fields
    if (!location || !location.coordinates || !Array.isArray(location.coordinates)) {
      return res.status(400).json({
        success: false,
        message: "Location coordinates must be an array [longitude, latitude]"
      });
    }

    const [longitude, latitude] = location.coordinates;

    // Validate coordinates
    if (!isValidCoordinates(longitude, latitude)) {
      return res.status(400).json({
        success: false,
        message: "Invalid coordinates. Longitude must be between -180 and 180, latitude between -90 and 90"
      });
    }

    // Format location as GeoJSON
    const geoJSONLocation = {
      type: 'Point',
      coordinates: [longitude, latitude] // MongoDB expects [longitude, latitude]
    };

    // Create provider with validated location
    const provider = new Provider({
      name,
      email,
      password,
      phoneNumber,
      businessName,
      businessAddress,
      serviceOffered,
      location: geoJSONLocation,
      isAvailable: false,
      rating: 0,
      totalRatings: 0
    });

    await provider.save();

    // Generate token and send response
    const token = generateToken(provider._id);
    res.status(201).json({
      success: true,
      token,
      provider
    });

  } catch (error) {
    console.error('Provider signup error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Error creating service provider account'
    });
  }
};

// Add coordinate validation helper
const isValidCoordinates = (longitude, latitude) => {
  if (typeof longitude !== 'number' || typeof latitude !== 'number') {
    return false;
  }
  
  if (isNaN(longitude) || isNaN(latitude)) {
    return false;
  }

  // Check longitude range (-180 to 180)
  if (longitude < -180 || longitude > 180) {
    return false;
  }

  // Check latitude range (-90 to 90)
  if (latitude < -90 || latitude > 90) {
    return false;
  }

  return true;
};
