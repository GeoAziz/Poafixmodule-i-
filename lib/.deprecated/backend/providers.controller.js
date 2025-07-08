const Provider = require('../models/provider.model');

exports.getNearbyProviders = async (req, res) => {
    try {
        const {
            latitude,
            longitude,
            radius = 5000,  // Default 5km
            serviceOffered
        } = req.query;

        // Validate parameters
        if (!latitude || !longitude || !serviceOffered) {
            return res.status(400).json({
                success: false,
                message: 'Missing required parameters: latitude, longitude, serviceOffered'
            });
        }

        // Convert parameters to numbers
        const lat = parseFloat(latitude);
        const lng = parseFloat(longitude);
        const maxDistance = parseFloat(radius);

        // Perform geospatial query
        const providers = await Provider.aggregate([
            {
                $geoNear: {
                    near: {
                        type: 'Point',
                        coordinates: [lng, lat] // MongoDB uses [longitude, latitude] order
                    },
                    distanceField: 'distance',
                    maxDistance: maxDistance,
                    spherical: true,
                    query: {
                        serviceOffered: serviceOffered,
                        isVerified: true,
                        isAvailable: true
                    }
                }
            },
            {
                $project: {
                    _id: 1,
                    name: 1,
                    businessName: 1,
                    rating: 1,
                    location: 1,
                    distance: 1,
                    isAvailable: 1,
                    phoneNumber: 1,
                    email: 1,
                    serviceOffered: 1
                }
            }
        ]);

        if (!providers.length) {
            return res.status(200).json([]);
        }

        return res.status(200).json(providers);

    } catch (error) {
        console.error('Error in getNearbyProviders:', error);
        return res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};
