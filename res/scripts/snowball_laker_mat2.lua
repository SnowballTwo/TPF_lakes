local mat2 = {}

function mat2.det(m)
    return m[1][1] * m[2][2] - m[1][2] * m[2][1]
end

function mat2.rot(angle)
    return {
        {math.cos(angle), -math.sin(angle)},
        {math.sin(angle), math.cos(angle)}
    }
end

function mat2.mul(matrix, vector)
    return {
        matrix[1][1] * vector[1] +  matrix[1][2] * vector[2],
        matrix[2][1] * vector[1] +  matrix[2][2] * vector[2],
    }
end

return mat2
